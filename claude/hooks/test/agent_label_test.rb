#!/usr/bin/env -S ruby --disable-gems
# Runs claude/hooks/agent-label as a subprocess against a stub Mattermost on
# 127.0.0.1. PATH is pinned and HOME is a temp dir, so nothing reaches a real
# server, a real binary or the real label log.
#
# usage: ruby claude/hooks/test/agent_label_test.rb
require "json"
require "socket"
require "tmpdir"
require "open3"

HOOK = File.expand_path("../agent-label", __dir__)
RUBY = RbConfig.ruby
ME = "valuser000000000000000000a"
HUMAN = "humanuser00000000000000000"
BOT = "botuser0000000000000000000"
MARSHAL = "b95ou57fj3rctq5t9amz5asbse"
FOOTER = "_sent by V via local agent_"

USERS = {
  ME => {"id" => ME, "username" => "valentino", "is_bot" => false},
  HUMAN => {"id" => HUMAN, "username" => "nick", "is_bot" => false},
  BOT => {"id" => BOT, "username" => "fidus-choragus", "is_bot" => true},
  MARSHAL => {"id" => MARSHAL, "username" => "dispensator-finitor", "is_bot" => true}
}.freeze
CHANNELS = {
  "pubchan" => {"id" => "pubchan", "type" => "O", "name" => "team-fde"},
  "dmhuman" => {"id" => "dmhuman", "type" => "D", "name" => "#{HUMAN}__#{ME}"},
  "dmbot" => {"id" => "dmbot", "type" => "D", "name" => "#{ME}__#{BOT}"}
}.freeze
THREADS = {
  "rootplain" => [ME, HUMAN],
  "rootbot" => [ME, BOT],
  "rootmarshal" => [ME, MARSHAL]
}.freeze

# One request per connection, enough for Net::HTTP.
def serve(server, hits)
  loop do
    client = server.accept
    line = client.gets.to_s
    verb, path = line.split(" ")
    headers = {}
    while (h = client.gets) && h != "\r\n"
      k, v = h.split(":", 2)
      headers[k.downcase] = v.to_s.strip
    end
    body = headers["content-length"] ? client.read(headers["content-length"].to_i) : nil
    hits << path
    status, payload = route(verb, path, body)
    data = JSON.generate(payload)
    client.write("HTTP/1.1 #{status} X\r\nContent-Type: application/json\r\nContent-Length: #{data.bytesize}\r\nConnection: close\r\n\r\n#{data}")
    client.close
  end
rescue IOError, Errno::EBADF
  nil
end

def route(verb, path, body)
  case path
  when "/api/v4/users/me" then [200, USERS[ME]]
  when "/api/v4/users/usernames"
    names = JSON.parse(body)
    [200, USERS.values.select { |u| names.include?(u["username"]) }]
  when %r{\A/api/v4/users/(\w+)\z} then USERS[$1] ? [200, USERS[$1]] : [404, {}]
  when %r{\A/api/v4/channels/(\w+)\z} then CHANNELS[$1] ? [200, CHANNELS[$1]] : [404, {}]
  when %r{\A/api/v4/posts/(\w+)/thread\z}
    ids = THREADS[$1] or return [404, {}]
    [200, {"posts" => ids.each_with_index.to_h { |u, i| ["p#{i}", {"user_id" => u}] }}]
  else [500, {}]
  end
end

server = TCPServer.new("127.0.0.1", 0)
PORT = server.addr[1]
HITS = Queue.new
Thread.new { serve(server, HITS) }
TMP = Dir.mktmpdir("agent-label-test")
LOG = File.join(TMP, "log.jsonl")

def run_hook(tool, input, env = {})
  base = {
    "PATH" => "/usr/bin:/bin", "HOME" => TMP, "MM_TOKEN" => "test-token",
    "AGENT_LABEL_MM_URL" => "http://127.0.0.1:#{PORT}", "AGENT_LABEL_LOG" => LOG,
    "CLAUDE_CODE_REMOTE" => nil
  }
  payload = JSON.generate("hook_event_name" => "PreToolUse", "tool_name" => tool, "tool_input" => input)
  out, err, st = Open3.capture3(base.merge(env), RUBY, "--disable-gems", HOOK, stdin_data: payload, unsetenv_others: true)
  raise "hook exited #{st.exitstatus}: #{err}" unless st.success?
  out.strip.empty? ? nil : JSON.parse(out)
end

def run_hook_payload(tool, input, extra)
  base = {
    "PATH" => "/usr/bin:/bin", "HOME" => TMP, "MM_TOKEN" => "test-token",
    "AGENT_LABEL_MM_URL" => "http://127.0.0.1:#{PORT}", "AGENT_LABEL_LOG" => LOG
  }
  payload = JSON.generate({"hook_event_name" => "PreToolUse", "tool_name" => tool, "tool_input" => input}.merge(extra))
  out, err, st = Open3.capture3(base, RUBY, "--disable-gems", HOOK, stdin_data: payload, unsetenv_others: true, chdir: "/")
  raise "hook exited #{st.exitstatus}: #{err}" unless st.success?
  out.strip.empty? ? nil : JSON.parse(out)
end

def last_outcome
  JSON.parse(File.readlines(LOG).last)["outcome"]
end

$failed = 0
def check(name, got, want)
  ok = got == want
  $failed += 1 unless ok
  puts "  #{ok ? "ok  " : "FAIL"} #{name}#{ok ? "" : ": got #{got.inspect} want #{want.inspect}"}"
end

def updated(out) = out&.dig("hookSpecificOutput", "updatedInput")

# ---- Mattermost ---------------------------------------------------------------
out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "message" => "hello team"})
check("channel post gets the footer", updated(out)&.dig("message"), "hello team\n\n#{FOOTER}")
check("no permission decision, so the normal prompt flow holds", out.dig("hookSpecificOutput").key?("permissionDecision"), false)
check("label is logged", last_outcome, "labelled")

out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "message" => "hello", "root_id" => nil, "file_ids" => ["f1"]})
check("other fields survive the rewrite", updated(out)&.dig("file_ids"), ["f1"])

out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "message" => "hi"}, "CLAUDE_CODE_REMOTE" => "true")
check("cloud session says cloud", updated(out)&.dig("message"), "hi\n\n_sent by V via cloud agent_")

out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "message" => "x\n\n#{FOOTER}"})
check("already labelled is left alone", out, nil)

out = run_hook("mcp__mattermost__compose", {"post_id" => "p1", "message" => "edited text"})
check("an edit is never touched", out, nil)
check("and is logged as an edit", last_outcome, "exempt:edit")

out = run_hook("mcp__mattermost__direct_message", {"user_id" => HUMAN, "message" => "hey"})
check("DM to a person gets the footer", updated(out)&.dig("message"), "hey\n\n#{FOOTER}")

pulse = "**For the pulse**\nDate: 2026-11-17\nTitle: x\nNeeds: none today"
out = run_hook("mcp__mattermost__direct_message", {"user_id" => MARSHAL, "message" => pulse})
check("DM to Marshal: hook output is empty, the pulse goes out byte for byte", out, nil)
check("logged as a bot DM", last_outcome, "exempt:dm-bot")

out = run_hook("mcp__mattermost__compose", {"channel_id" => "dmbot", "message" => "hi"})
check("compose into a DM channel with a bot: no footer", out, nil)
out = run_hook("mcp__mattermost__compose", {"channel_id" => "dmhuman", "message" => "hi"})
check("compose into a DM channel with a person: footer", updated(out)&.dig("message"), "hi\n\n#{FOOTER}")

out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "message" => "@fidus-choragus can you look"})
check("@-mention of a bot: no footer", out, nil)
check("logged as a bot mention", last_outcome, "exempt:mention-bot")
out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "message" => "@nick and @channel see this."})
check("@-mention of a person and @channel: footer", updated(out)&.dig("message")&.end_with?(FOOTER), true)

out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "root_id" => "rootmarshal", "message" => "stop"})
check("reply in a thread Marshal posted in: no footer", out, nil)
check("logged with the legate", last_outcome, "exempt:thread-marshal")
out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "root_id" => "rootbot", "message" => "thanks"})
check("reply in a thread another bot posted in: footer", updated(out)&.dig("message"), "thanks\n\n#{FOOTER}")
out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "root_id" => "rootplain", "message" => "ok"})
check("reply in a human thread: footer", updated(out)&.dig("message"), "ok\n\n#{FOOTER}")

out = run_hook("mcp__mattermost__compose", {"channel_id" => "nosuch", "message" => "hi"})
check("failed lookup: no footer", updated(out), nil)
check("failed lookup: says so in context", out&.dig("hookSpecificOutput", "additionalContext")&.include?("No agent label"), true)
check("failed lookup: logged as a skip", last_outcome.start_with?("skipped:"), true)
out = run_hook("mcp__mattermost__compose", {"message" => "hi"})
check("no channel_id (current channel unknown): denied", out&.dig("hookSpecificOutput", "permissionDecision"), "deny")
check("and logged", last_outcome, "denied:no-channel-id")
out = run_hook("mcp__mattermost__compose", {"post_id" => "p1", "message" => "edit"})
check("an edit with no channel_id is still untouched", out, nil)
out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "message" => "hi"}, "AGENT_LABEL_MM_URL" => "http://127.0.0.1:1")
check("server unreachable: no footer", updated(out), nil)
out = run_hook("mcp__mattermost__compose", {"channel_id" => "pubchan", "message" => "hi"}, "MM_TOKEN" => nil)
check("no token: skipped", last_outcome, "skipped:no MM_TOKEN")

# ---- Linear and Fizzy -------------------------------------------------------------
out = run_hook("mcp__linear-server__save_comment", {"issueId" => "CORE-1", "body" => "Looks good"})
check("Linear comment create: footer", updated(out)&.dig("body"), "Looks good\n\n#{FOOTER}")
out = run_hook("mcp__linear-server__save_comment", {"id" => "c1", "body" => "fixed"})
check("Linear comment edit: untouched", out, nil)
out = run_hook("mcp__linear-server__save_issue", {"team" => "Core", "title" => "t", "description" => "d"})
check("Linear issue create: footer on description", updated(out)&.dig("description"), "d\n\n#{FOOTER}")
out = run_hook("mcp__linear-server__save_issue", {"team" => "Core", "title" => "t"})
check("Linear issue create with no description: footer alone", updated(out)&.dig("description"), "\n\n#{FOOTER}")
out = run_hook("mcp__linear-server__save_issue", {"id" => "CORE-1", "state" => "Done"})
check("Linear issue update: untouched", out, nil)
out = run_hook("mcp__fizz-mcp__add_comment", {"card_number" => 1, "content" => "<p>hi</p>"})
check("Fizzy comment: html footer", updated(out)&.dig("content"), "<p>hi</p><p><em>sent by V via local agent</em></p>")
out = run_hook("mcp__fizz-mcp__comment_cards", {"card_numbers" => [1, 2], "content" => "hi"})
check("Fizzy bulk comment: footer, card list kept", [updated(out)&.dig("content")&.end_with?("</em></p>"), updated(out)&.dig("card_numbers")], [true, [1, 2]])
out = run_hook("mcp__fizz-mcp__create_card", {"title" => "t", "description" => nil})
check("Fizzy card create: footer", updated(out)&.dig("description"), "<p><em>sent by V via local agent</em></p>")

# ---- gh -----------------------------------------------------------------------------
deny = lambda { |o| o&.dig("hookSpecificOutput", "permissionDecision") }
check("gh pr comment without footer: denied", deny.(run_hook("Bash", {"command" => %(gh pr comment 12 --body "lgtm")})), "deny")
check("deny reason names the line", run_hook("Bash", {"command" => %(gh pr comment 12 --body "lgtm")}).dig("hookSpecificOutput", "permissionDecisionReason").include?(FOOTER), true)
check("gh pr comment with footer: allowed", run_hook("Bash", {"command" => %(gh pr comment 12 --body "lgtm\n\n#{FOOTER}")}), nil)
check("gh pr create with no body: denied", deny.(run_hook("Bash", {"command" => "gh pr create --draft --fill"})), "deny")
body = File.join(TMP, "body.md")
File.write(body, "What it does.\n\n#{FOOTER}\n")
check("gh pr create --body-file with footer: allowed", run_hook("Bash", {"command" => "gh pr create --draft --title t --body-file #{body}"}), nil)
File.write(body, "What it does.\n")
check("gh pr create --body-file without footer: denied", deny.(run_hook("Bash", {"command" => "gh pr create --draft --title t --body-file #{body}"})), "deny")
check("gh issue comment without footer: denied", deny.(run_hook("Bash", {"command" => %(gh issue comment 3 -b "x")})), "deny")
check("gh pr review --approve with no body: allowed", run_hook("Bash", {"command" => "gh pr review 12 --approve"}), nil)
check("gh pr review with a body: denied", deny.(run_hook("Bash", {"command" => %(gh pr review 12 --comment -b "nit")})), "deny")
check("gh pr edit: not matched", run_hook("Bash", {"command" => %(gh pr edit 12 --body "x")}), nil)
check("gh pr view: not matched", run_hook("Bash", {"command" => "gh pr view 12"}), nil)
check("unrelated Bash: not matched", run_hook("Bash", {"command" => "ls"}), nil)
check("quoted gh in an ag pattern: not matched", run_hook("Bash", {"command" => "ag 'gh pr create' bin/"}), nil)
check("gh in a commit message: not matched", run_hook("Bash", {"command" => %(git commit -m "deny gh pr comment without footer")}), nil)
check("gh in a zar-say body: not matched", run_hook("Bash", {"command" => %(zar-say Review "run gh pr create later")}), nil)
check("gh after &&: matched", deny.(run_hook("Bash", {"command" => %(cd x && gh pr comment 1 --body "y")})), "deny")
check("gh with an env prefix: matched", deny.(run_hook("Bash", {"command" => %(GH_HOST=x gh issue create -b "y")})), "deny")
check("gh after a newline: matched", deny.(run_hook("Bash", {"command" => %(cd x\ngh pr comment 1 -b "y")})), "deny")
Dir.mkdir(File.join(TMP, "repo")) unless Dir.exist?(File.join(TMP, "repo"))
File.write(File.join(TMP, "repo", "pr.md"), "Body.\n\n#{FOOTER}\n")
rel = lambda { |cwd| run_hook_payload("Bash", {"command" => "gh pr create --draft --title t --body-file pr.md"}, "cwd" => cwd) }
check("relative --body-file resolves against the payload cwd", rel.(File.join(TMP, "repo")), nil)
check("and is denied when the cwd holds no such labelled file", deny.(rel.(TMP)), "deny")

# ---- other tools ------------------------------------------------------------------
check("other MCP tools: untouched", run_hook("mcp__mattermost__react", {"post_id" => "p", "emoji" => "+1"}), nil)

check("no log line holds message text", File.read(LOG).include?("hello team"), false)

puts
puts $failed.zero? ? "agent-label: all assertions pass" : "agent-label: #{$failed} FAILED"
exit($failed.zero? ? 0 : 1)
