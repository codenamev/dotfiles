#!/usr/bin/env python3
"""Deterministic beans -> Notion state push.

Mechanical layer of the two-layer tracking system: keeps Notion tasks that are
already linked to a bean (via the Bean ID property) in sync with local beans
state. One way, beans -> Notion. Creating new Notion tasks and publishing doc
artifacts is the agent's judgment call and is deliberately left out of here.

Design constraints:
- Never fail a session. Missing config, missing token, or a Notion error exits 0.
- Diff-gated. If beans state is unchanged since the last successful run, do no
  network work at all.
- Config-driven. Nothing about a specific dashboard is hardcoded; everything
  comes from env + a local config file, so the script is shareable as-is.

Config:
- env NOTION_TOKEN            Notion internal integration token
- .beans/notion-sync.config.json
    {
      "database_id": "<uuid of the Tasks Tracker database>",
      "properties": {            # optional overrides; defaults shown
        "bean_id": "Bean ID",
        "title":   "Task name",
        "status":  "Status",
        "priority":"Priority"
      },
      "status_map":   {"open":"Not started","in_progress":"In progress","closed":"Done"},
      "priority_map": {"0":"High","1":"High","2":"Medium","3":"Low","4":"Low"}
    }

Usage: beans-notion-sync.py [--verbose]
Prints a one-line summary to stdout. Exit code is always 0.
"""

import json
import os
import subprocess
import sys
import urllib.request
import urllib.error

NOTION_VERSION = "2022-06-28"
API = "https://api.notion.com/v1"

DEFAULT_PROPS = {"bean_id": "Bean ID", "title": "Task name",
                 "status": "Status", "priority": "Priority"}
DEFAULT_STATUS = {"open": "Not started", "in_progress": "In progress", "closed": "Done"}
DEFAULT_PRIORITY = {"0": "High", "1": "High", "2": "Medium", "3": "Low", "4": "Low"}

VERBOSE = "--verbose" in sys.argv


def log(msg):
    if VERBOSE:
        print(msg, file=sys.stderr)


def plain_text_of(rich_text):
    """Concatenate the plain_text of a Notion rich_text or title array. Tolerates
    a missing/None value or non-dict entries from a malformed Notion response."""
    if not isinstance(rich_text, list):
        return ""
    return "".join(t.get("plain_text", "") for t in rich_text if isinstance(t, dict))


def beans_dir():
    """Locate the .beans directory by walking up from cwd."""
    d = os.getcwd()
    while True:
        candidate = os.path.join(d, ".beans")
        if os.path.isdir(candidate):
            return candidate
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def load_config(bdir):
    token = os.environ.get("NOTION_TOKEN")
    cfg_path = os.path.join(bdir, "notion-sync.config.json")
    if not token:
        log("NOTION_TOKEN is not set in the environment; sync is off")
        return None
    if not os.path.exists(cfg_path):
        log("no notion-sync.config.json; sync is off")
        return None
    try:
        with open(cfg_path) as f:
            cfg = json.load(f)
    except (OSError, ValueError) as e:
        # Distinguish a malformed/unreadable config from "no config present"
        # (which returns None earlier without logging).
        log(f"notion-sync.config.json present but unreadable: {e}")
        return None
    if not isinstance(cfg, dict):
        # Valid JSON that is not an object (a list, string, number) would crash
        # the cfg.get() calls below; treat it as no usable config.
        log("notion-sync.config.json is not a JSON object; skipping sync")
        return None
    if not cfg.get("database_id"):
        log("notion-sync.config.json has no database_id; sync is off")
        return None
    cfg["token"] = token
    cfg["properties"] = {**DEFAULT_PROPS, **cfg.get("properties", {})}
    cfg["status_map"] = {**DEFAULT_STATUS, **cfg.get("status_map", {})}
    cfg["priority_map"] = {**DEFAULT_PRIORITY, **cfg.get("priority_map", {})}
    return cfg


def list_beans():
    """Return the list of beans, or None if the query failed (vs [] for a
    successful query that found none) so the caller can tell a broken/absent
    beans from an empty workspace."""
    try:
        out = subprocess.run(["beans", "--json", "list"], capture_output=True,
                             text=True, timeout=15)
        if out.returncode != 0:
            log(f"beans list exited {out.returncode}: {out.stderr.strip()}")
            return None
        data = json.loads(out.stdout)
        if not isinstance(data, list):
            log("beans list did not return a JSON array; treating as a failed query")
            return None
        return data
    except FileNotFoundError:
        log("beans executable not found; skipping sync")
        return None
    except (OSError, subprocess.SubprocessError, ValueError) as e:
        # OSError covers a non-executable beans (PermissionError) and the like.
        log(f"beans list failed or returned malformed JSON: {e}")
        return None


def desired_state(beans, cfg):
    """Map each bean to the Notion values it should carry."""
    state = {}
    for b in beans:
        bid = str(b.get("id", ""))
        if not bid:
            continue
        # Treat a null/missing status as empty, not the string "None": a bean
        # with no status should be skipped, not logged as an unmapped "None".
        raw_status = str(b.get("status") or "")
        mapped_status = cfg["status_map"].get(raw_status, None)
        if raw_status and mapped_status is None:
            # An unmapped status never syncs (the trigger skips a falsy status);
            # surface it so a newly added beans status isn't silently ignored.
            log(f"bean {bid}: status {raw_status!r} has no status_map entry; not synced")
        state[bid] = {
            "title": b.get("title", ""),
            "status": mapped_status,
            "priority": cfg["priority_map"].get(str(b.get("priority", "")), None),
        }
    return state


def state_hash(state):
    # Full desired state. Any local change (status, title, or priority) opens the
    # gate; the per-bean trigger then pushes only the fields that actually differ
    # from Notion's current values, so a title- or priority-only change is synced
    # rather than dropped, and the gate never advances past an unsynced change.
    return json.dumps(state, sort_keys=True)


def api(method, path, cfg, body=None):
    url = f"{API}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": f"Bearer {cfg['token']}",
        "Notion-Version": NOTION_VERSION,
        "Content-Type": "application/json",
    })
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read().decode())


def linked_pages(cfg):
    """Return ({bean_id: {page_id, status, title, priority}}, duplicate_bids) for
    Notion tasks with a Bean ID set. Title and priority are read so the sync can
    detect drift in those fields, not just status. duplicate_bids is the set of
    Bean IDs that appeared on more than one page (only one is kept)."""
    props = cfg["properties"]
    result = {}
    duplicates = set()
    cursor = None
    while True:
        body = {"filter": {"property": props["bean_id"],
                           "rich_text": {"is_not_empty": True}}, "page_size": 100}
        if cursor:
            body["start_cursor"] = cursor
        page = api("POST", f"/databases/{cfg['database_id']}/query", cfg, body)
        if not isinstance(page, dict):
            # Notion returned something other than an object (e.g. null during an
            # outage); stop rather than AttributeError on .get().
            log("Notion query returned a non-object response; stopping")
            break
        results = page.get("results", [])
        if not isinstance(results, list):
            log("Notion query 'results' was not a list; stopping")
            break
        for row in results:
            if not isinstance(row, dict):
                continue
            rp = row.get("properties") or {}
            rt = (rp.get(props["bean_id"]) or {}).get("rich_text", [])
            bid = plain_text_of(rt).strip()
            if not bid:
                continue
            page_id = row.get("id")
            if not page_id:
                # Without a page id there is nothing to patch; skip before the
                # duplicate check so it isn't counted as the "kept" page.
                log(f"Notion row for Bean ID {bid} has no id; skipping")
                continue
            if bid in result:
                # Two Notion pages claim the same Bean ID; only one can win, so
                # the other stops receiving updates. Track it for the summary and
                # log it so the user can resolve the duplicate.
                duplicates.add(bid)
                log(f"duplicate Bean ID {bid} in Notion; keeping the last page seen")
            status_prop = (rp.get(props["status"]) or {}).get("status")
            title_rt = (rp.get(props["title"]) or {}).get("title", [])
            priority_prop = (rp.get(props["priority"]) or {}).get("select")
            result[bid] = {
                "page_id": page_id,
                "status": status_prop.get("name") if status_prop else None,
                "title": plain_text_of(title_rt),
                "priority": priority_prop.get("name") if priority_prop else None,
            }
        cursor = page.get("next_cursor")
        if not page.get("has_more") or not cursor:
            # Stop when Notion says there is no more, and also when has_more is
            # set but the cursor is missing/null — otherwise the next iteration
            # would drop start_cursor and re-query page one forever.
            break
    return result, duplicates


def patch_page(page_id, changes, cfg):
    props = cfg["properties"]
    payload = {}
    if "status" in changes and changes["status"]:
        payload[props["status"]] = {"status": {"name": changes["status"]}}
    if "priority" in changes and changes["priority"]:
        payload[props["priority"]] = {"select": {"name": changes["priority"]}}
    if changes.get("title"):
        payload[props["title"]] = {"title": [{"text": {"content": changes["title"]}}]}
    if not payload:
        return False
    api("PATCH", f"/pages/{page_id}", cfg, {"properties": payload})
    return True


def main():
    bdir = beans_dir()
    if not bdir:
        return  # not in a beans workspace; nothing to do

    # Check config (cheap env + file reads) before listing beans (a subprocess +
    # SQLite read). On the common unconfigured case this skips the beans call.
    cfg = load_config(bdir)
    if not cfg:
        # Not configured for sync. Stay silent; the agent layer still works.
        return

    beans = list_beans()
    if beans is None:
        # The query itself failed (beans missing, crashed, or returned garbage),
        # which is different from a workspace with no beans. Surface it once to
        # stdout so a broken setup is visible without --verbose.
        print("beans->notion: could not read beans; sync skipped this run")
        return
    if not beans:
        return  # no beans yet; nothing to sync

    state = desired_state(beans, cfg)
    cur_hash = state_hash(state)
    state_path = os.path.join(bdir, "notion-sync.state.json")

    # Diff gate: if beans state is unchanged since the last successful push AND
    # every bean was already linked last run, there is nothing to send to Notion.
    # Skip all network work. We keep querying while any bean is still unlinked,
    # because a bean can be linked on the Notion side (its page gets a Bean ID)
    # without any change to the bean's own fields — the hash wouldn't move, so a
    # hash-only gate would skip that newly-linked page's first sync. The stored
    # `unlinked` count is absent on a pre-existing state file, so default to a
    # non-zero value to force one query that repopulates it.
    try:
        with open(state_path) as f:
            prev = json.load(f)
        if (isinstance(prev, dict) and prev.get("hash") == cur_hash
                and prev.get("unlinked", 1) == 0):
            log("beans state unchanged and all beans linked; skipping sync")
            return
    except (OSError, ValueError) as e:
        # A missing state file is normal (first run); a corrupt one shouldn't
        # crash. Either way we fall through and sync. Note the corrupt case so a
        # repeatedly-skipped diff gate is debuggable.
        log(f"could not read sync state (treating as first run): {e}")

    try:
        linked, duplicates = linked_pages(cfg)
    except (OSError, urllib.error.URLError, urllib.error.HTTPError, ValueError) as e:
        log(f"Notion query failed: {e}")
        return  # leave state file untouched so we retry next time

    pushed = 0
    failed = 0
    linked_ids = set(linked) & set(state)
    for bid in linked_ids:
        want = state[bid]
        have = linked[bid]
        # Push only the fields that actually differ from Notion's current values.
        # A blank desired value is skipped so an empty title/priority never wipes
        # what is already in Notion.
        changes = {}
        for field in ("status", "title", "priority"):
            if want[field] and want[field] != have.get(field):
                changes[field] = want[field]
        if not changes:
            continue
        try:
            if patch_page(have["page_id"], changes, cfg):
                pushed += 1
        except (OSError, urllib.error.URLError, urllib.error.HTTPError, ValueError) as e:
            failed += 1
            log(f"patch {bid} failed: {e}")

    unlinked = [b for b in state if b not in linked]

    # Advance the diff gate only when every attempted push succeeded. If any
    # failed, leave the state file untouched so the next run retries them rather
    # than marking them permanently synced behind an up-to-date hash. Record the
    # unlinked count so the gate stays open next run while linking is still
    # pending (see the gate above).
    if failed == 0:
        try:
            with open(state_path, "w") as f:
                json.dump({"hash": cur_hash, "unlinked": len(unlinked)}, f)
        except OSError as e:
            # A failed write leaves the gate open, so next run re-queries and
            # re-pushes the same (idempotent) changes. Surface it under --verbose.
            log(f"could not write sync state file: {e}")
    else:
        log(f"{failed} push(es) failed; not advancing the state gate so they retry")

    summary = f"beans->notion: {pushed} task(s) updated"
    if failed:
        summary += f", {failed} failed (will retry next run)"
    if unlinked:
        summary += f", {len(unlinked)} local bean(s) not yet in Notion"
    if duplicates:
        # Visible without --verbose: a duplicate Bean ID means one page silently
        # stops updating, so the user needs to resolve it.
        summary += f", {len(duplicates)} duplicate Bean ID(s) in Notion (resolve: {', '.join(sorted(duplicates))})"
    print(summary)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # never break a session
        log(f"sync error: {e}")
        # Stay exit-0, but emit one line so a persistent failure is not fully
        # invisible when the Stop hook runs without --verbose.
        print("beans->notion: sync hit an unexpected error (run with --verbose for details)")
    sys.exit(0)
