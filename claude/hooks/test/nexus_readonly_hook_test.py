#!/usr/bin/python3 -I
# Runs claude/hooks/nexus-readonly-hook as a subprocess. PATH is an empty temp
# dir and HOME a temp dir, so nothing reaches Nexus or a real binary on PATH.
#
# Root ownership cannot be set up here, so most cases run a patched copy of
# the hook with three constants swapped: the approval directory (a temp dir),
# the required owner (this uid) and the append-only flag (UF_APPEND, which a
# user can set). The shipped hook has no runtime seam. SABOTAGE deletes one
# check at a time from a further copy and asserts the cases aimed at it fail.
#
# usage: /usr/bin/python3 -I claude/hooks/test/nexus_readonly_hook_test.py
import datetime
import hashlib
import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "nexus-readonly-hook")
SOURCE = open(HOOK).read()
PATCHES = [
    ('APPROVAL_DIR = "/etc/zar"', 'APPROVAL_DIR = {dir!r}'),
    ("APPROVAL_OWNER = 0", "APPROVAL_OWNER = {uid}"),
    ("APPEND_FLAG = stat.SF_APPEND", "APPEND_FLAG = stat.UF_APPEND"),
]
U = "https://nexus.zar.app/learning/abc"
P = "https://nexus.zar.app/ontology#title"
PINNED = "pinned text"


def sha(s):
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def tomorrow():
    t = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1)
    return t.strftime("%Y-%m-%dT%H:%M:%SZ")


def approval(**over):
    a = {
        "approved_by": "valentino",
        "expires_at": tomorrow(),
        "tools": ["ingest", "set_literal"],
        "session_ids": ["s1", "s2", "s3"],
        "content_sha256": {"s3": sha(PINNED)},
        "set_literal_targets": [{"uri": U, "predicate": P}],
    }
    a.update(over)
    return {k: v for k, v in a.items() if v is not None}


def ingest(sid="s1", extra=""):
    return f'call_tool("ingest", content: "x", session_id: "{sid}"{extra})'


class Box:
    """A temp approval dir, log and patched hook for one case."""

    def __init__(self, source=SOURCE, patch_owner=True):
        self.tmp = tempfile.TemporaryDirectory()
        root = self.tmp.name
        self.dir = os.path.join(root, "zar")
        os.mkdir(self.dir, 0o755)
        self.approval = os.path.join(self.dir, "nexus-oneshot.json")
        self.log = os.path.join(self.dir, "nexus-oneshot.consumed.jsonl")
        self.bin = os.path.join(root, "emptybin")
        self.home = os.path.join(root, "home")
        os.mkdir(self.bin)
        os.mkdir(self.home)
        s = source
        for old, new in PATCHES:
            if old == "APPROVAL_OWNER = 0" and not patch_owner:
                continue
            assert old in s, old
            s = s.replace(old, new.format(dir=self.dir, uid=os.getuid()))
        self.hook = os.path.join(root, "hook")
        with open(self.hook, "w") as f:
            f.write(s)
        os.chmod(self.hook, 0o755)

    def write_approval(self, a, mode=0o644):
        with open(self.approval, "w") as f:
            f.write(a if isinstance(a, str) else json.dumps(a))
        os.chmod(self.approval, mode)

    def make_log(self, flag=True):
        open(self.log, "w").close()
        if flag:
            os.chflags(self.log, stat.UF_APPEND)

    def close(self):
        if os.path.exists(self.log):
            os.chflags(self.log, 0)
        os.chmod(self.dir, 0o755)
        self.tmp.cleanup()


def run(hook, code, home, path):
    r = subprocess.run([hook], input=json.dumps({"tool_input": {"code": code}}).encode(),
                       capture_output=True, timeout=60, env={"PATH": path, "HOME": home})
    return r.returncode, r.stderr.decode()


# name -> dict(code or runs, expect, setup tweaks)
# runs: list of (code, rc, stderr substring); setup: fn(box) after defaults.
CASES = {
    # unchanged read behaviour
    "read_query": dict(runs=[('call_tool("query", query: "SELECT 1")', 0, "")]),
    "read_send": dict(runs=[('send(:call_tool, "ingest")', 2, "dynamic dispatch")]),
    "read_var_name": dict(runs=[('t = "ingest"; call_tool(t)', 2, "literal string")]),
    "read_unknown": dict(runs=[('call_tool("delete_entity", uri: "x")', 2, "not a read tool: delete_entity")]),
    # approved writes
    "w_once": dict(runs=[(ingest("s1"), 0, ""), (ingest("s1"), 2, "already used")]),
    "w_command_form": dict(runs=[('call_tool "ingest", content: "x", session_id: "s1"', 0, "")]),
    "w_two_ids": dict(runs=[(ingest("s1") + "\n" + ingest("s2"), 0, "")]),
    "w_read_and_write": dict(runs=[('call_tool("query", query: "q")\n' + ingest("s2"), 0, "")]),
    "w_unlisted": dict(runs=[(ingest("zz"), 2, "not in the approval")]),
    "w_interp": dict(runs=[('call_tool("ingest", content: "x", session_id: "s#{1}")', 2, "plain quoted string")]),
    "w_variable": dict(runs=[('sid = "s1"\ncall_tool("ingest", content: "x", session_id: sid)', 2, "plain quoted string")]),
    "w_missing_id": dict(runs=[('call_tool("ingest", content: "x")', 2, "needs a session_id")]),
    "w_same_id_twice": dict(runs=[(ingest("s1") + "\n" + ingest("s1"), 2, "used twice")]),
    "w_block": dict(runs=[("[1, 2].each { |i| " + ingest("s1") + " }", 2, "inside a block")]),
    "w_do_block": dict(runs=[("2.times do\n" + ingest("s1") + "\nend", 2, "inside a block")]),
    "w_lambda": dict(runs=[("f = -> { " + ingest("s1") + " }\nf.call\nf.call", 2, "inside a block")]),
    "w_while": dict(runs=[("i = 0\nwhile i < 2\n" + ingest("s1") + "\ni += 1\nend", 2, "inside a block")]),
    "w_modifier_loop": dict(runs=[("i = 0\n" + ingest("s1") + " while (i += 1) < 3", 2, "inside a block")]),
    "w_def": dict(runs=[("def go\n" + ingest("s1") + "\nend\ngo\ngo", 2, "inside a block")]),
    "w_retry": dict(runs=[("n = 0\nbegin\n" + ingest("s1") + "\nraise 'x' if (n += 1) < 3\nrescue\nretry\nend", 2, "retry and redo")]),
    "w_splat": dict(runs=[('o = {session_id: "s1"}\ncall_tool("ingest", content: "x", **o)', 2, "plain label")]),
    "w_hash_rocket": dict(runs=[('call_tool("ingest", content: "x", :session_id => "s1")', 2, "plain label")]),
    "w_receiver": dict(runs=[('self.call_tool("ingest", content: "x", session_id: "s1")', 2, "direct call")]),
    "w_symbol_alias": dict(runs=[('alias ct call_tool\nct("ingest", session_id: "s1")', 2, "literal string")]),
    "w_unparseable": dict(runs=[(ingest("s1") + "\nend end", 2, "does not parse")]),
    # pinned content
    "c_match": dict(runs=[(f'call_tool("ingest", content: "{PINNED}", session_id: "s3")', 0, "")]),
    "c_escaped_match": dict(runs=[('call_tool("ingest", content: "pinned\\x20text", session_id: "s3")', 0, "")]),
    "c_single_quoted": dict(runs=[(f"call_tool('ingest', content: '{PINNED}', session_id: 's3')", 0, "")]),
    "c_mismatch": dict(runs=[('call_tool("ingest", content: "other", session_id: "s3")', 2, "does not match")]),
    "c_interp": dict(runs=[('w = "text"\ncall_tool("ingest", content: "pinned #{w}", session_id: "s3")', 2, "plain quoted string")]),
    "c_heredoc": dict(runs=[('call_tool("ingest", session_id: "s3", content: <<~T)\n  pinned text\nT', 2, "plain quoted string")]),
    "c_missing": dict(runs=[('call_tool("ingest", session_id: "s3")', 2, "needs a content")]),
    # set_literal
    "sl_once": dict(runs=[(f'call_tool("set_literal", uri: "{U}", predicate: "{P}", value: "v")', 0, ""),
                          (f'call_tool("set_literal", uri: "{U}", predicate: "{P}", value: "w")', 2, "already used")]),
    "sl_other_uri": dict(runs=[(f'call_tool("set_literal", uri: "{U}x", predicate: "{P}", value: "v")', 2, "not in the approval")]),
    "sl_not_listed_tool": dict(approval=approval(tools=["ingest"]),
                               runs=[(f'call_tool("set_literal", uri: "{U}", predicate: "{P}", value: "v")', 2, "does not list set_literal")]),
    # approval and log state
    "a_no_file": dict(approval=False, runs=[(ingest(), 2, "no approval file")]),
    "a_expired": dict(approval=approval(expires_at="2020-01-01T00:00:00Z"), runs=[(ingest(), 2, "expired")]),
    "a_no_expiry": dict(approval=approval(expires_at=None), runs=[(ingest(), 2, "expires_at")]),
    "a_unknown_key": dict(approval=approval(note="hi"), runs=[(ingest(), 2, "unknown keys")]),
    "a_bad_json": dict(approval="{not json", runs=[(ingest(), 2, "not valid JSON")]),
    "a_bad_tool": dict(approval=approval(tools=["ingest", "delete_entity"]), runs=[(ingest(), 2, "malformed")]),
    "a_bad_hash": dict(approval=approval(content_sha256={"s3": "abc"}), runs=[(ingest(), 2, "malformed")]),
    "a_group_writable": dict(approval_mode=0o664, runs=[(ingest(), 2, "root-owned regular file")]),
    "a_dir_writable": dict(dir_mode=0o777, runs=[(ingest(), 2, "root-owned directory")]),
    "a_symlink": dict(symlink=True, runs=[(ingest(), 2, "symlink")]),
    "a_wrong_owner": dict(patch_owner=False, runs=[(ingest(), 2, "is not a root-owned")]),
    "a_changed_file_is_new_approval": dict(reissue=True, runs=[(ingest("s1"), 0, "")]),
    "log_no_flag": dict(log_flag=False, runs=[(ingest(), 2, "not append-only")]),
    "log_missing": dict(log=False, runs=[(ingest(), 2, "no consumption log")]),
    "log_garbage_ignored": dict(log_garbage=True, runs=[(ingest("s1"), 0, "")]),
}


def play(name, source=SOURCE):
    """Run one case; return a list of mismatch descriptions (empty = pass)."""
    c = CASES[name]
    box = Box(source, patch_owner=c.get("patch_owner", True))
    try:
        a = c.get("approval", approval())
        if a is not False:
            box.write_approval(a, c.get("approval_mode", 0o644))
        if c.get("symlink"):
            real = box.approval + ".real"
            os.rename(box.approval, real)
            os.symlink(real, box.approval)
        if c.get("log", True):
            box.make_log(c.get("log_flag", True))
        if c.get("log_garbage"):
            with open(box.log, "a") as f:
                f.write("not json\n{}\n")
        if c.get("reissue"):
            # s1 spent under the first approval, then Val rewrites the file.
            run(box.hook, ingest("s1"), box.home, box.bin)
            box.write_approval(approval(approved_by="valentino again"))
        os.chmod(box.dir, c.get("dir_mode", 0o755))
        bad = []
        for code, rc, want in c["runs"]:
            got_rc, err = run(box.hook, code, box.home, box.bin)
            if got_rc != rc or want not in err:
                bad.append(f"{name}: rc {got_rc} (want {rc}), stderr {err.strip()!r} (want {want!r})")
        return bad
    finally:
        box.close()


# check name -> (exact source to replace, replacement, cases that must now fail)
SABOTAGE = {
    "owner": ("st.st_uid == owner and ", "", ["a_wrong_owner"]),
    "group_write": ("and not st.st_mode & (stat.S_IWGRP | stat.S_IWOTH)", "", ["a_group_writable", "a_dir_writable"]),
    "symlink": ("os.O_RDONLY | os.O_NOFOLLOW", "os.O_RDONLY", ["a_symlink"]),
    "append_flag": ("if not st.st_flags & APPEND_FLAG:", "if False:", ["log_no_flag"]),
    "expiry": ("if datetime.datetime.now(datetime.timezone.utc) >= expires:", "if False:", ["a_expired"]),
    "listed_id": ('if sid not in a["session_ids"]:', "if False:", ["w_unlisted"]),
    "consumption": ("if (approval_sha, kind, value) in spent:", "if False:", ["w_once", "sl_once"]),
    "loop": ('if call["looped"]:', "if False:", ["w_block", "w_do_block", "w_lambda", "w_while", "w_modifier_loop", "w_def"]),
    "retry": ('if tree["redo_or_retry"]:', "if False:", ["w_retry"]),
    "literal_args": ('if "bad" in v:', "if False:", ["w_interp", "w_variable", "c_interp", "c_heredoc"]),
    "content_hash": ('if pinned and arg(call, "content")["sha256"] != pinned:', "if False:", ["c_mismatch"]),
    "direct_call": ('if tree["unhandled"]:', "if False:", ["w_receiver"]),
    "set_literal_target": ('if target not in a.get("set_literal_targets", []):', "if False:", ["sl_other_uri"]),
    "same_id_twice": ("if len(set(keys)) != len(keys):", "if False:", ["w_same_id_twice"]),
}


class Cases(unittest.TestCase):
    pass


def _case(name):
    return lambda self: self.assertEqual([], play(name))


for _n in CASES:
    setattr(Cases, f"test_{_n}", _case(_n))


class Shipped(unittest.TestCase):
    """The unpatched hook, with whatever is at /etc/zar on this machine."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def test_reads_need_no_approval(self):
        self.assertEqual(0, run(HOOK, 'call_tool("search", query: "x")', self.home, self.home)[0])

    def test_write_with_unlisted_id_blocked(self):
        rc, err = run(HOOK, ingest("test-never-approved-id"), self.home, self.home)
        self.assertEqual(2, rc, err)

    def test_requires_root_and_system_append_flag(self):
        self.assertIn('APPROVAL_DIR = "/etc/zar"', SOURCE)
        self.assertIn("APPROVAL_OWNER = 0\n", SOURCE)
        self.assertIn("APPEND_FLAG = stat.SF_APPEND\n", SOURCE)
        self.assertTrue(SOURCE.startswith("#!/usr/bin/python3 -I\n"))
        self.assertIn('RUBY = "/usr/bin/ruby"\n', SOURCE)

    def test_concurrent_consumers_one_wins(self):
        box = Box()
        try:
            box.write_approval(approval())
            box.make_log()
            env = {"PATH": box.bin, "HOME": box.home}
            payload = json.dumps({"tool_input": {"code": ingest("s2")}}).encode()
            procs = [subprocess.Popen([box.hook], stdin=subprocess.PIPE, stderr=subprocess.DEVNULL, env=env) for _ in range(4)]
            for p in procs:
                p.stdin.write(payload)
                p.stdin.close()
            rcs = sorted(p.wait(timeout=60) for p in procs)
            self.assertEqual([0, 2, 2, 2], rcs)
            with open(box.log) as f:
                self.assertEqual(1, len(f.read().splitlines()))
        finally:
            box.close()


class Sabotage(unittest.TestCase):
    pass


def _sabotage(check, old, new, targets):
    def test(self):
        self.assertEqual(1, SOURCE.count(old), f"{check}: sabotage anchor must appear once")
        broken = SOURCE.replace(old, new)
        still_pass = [t for t in targets if not play(t, broken)]
        self.assertEqual([], still_pass, f"{check} removed, yet these cases still pass")
    return test


for _c, (_o, _r, _t) in SABOTAGE.items():
    setattr(Sabotage, f"test_without_{_c}", _sabotage(_c, _o, _r, _t))


if __name__ == "__main__":
    unittest.main(verbosity=1)
