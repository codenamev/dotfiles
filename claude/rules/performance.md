## Model Selection Strategy

**Haiku 4.5** (`claude-haiku-4-5`) — fast and cheap:
- Lightweight agents with frequent invocation
- Worker agents in multi-agent systems
- Mechanical edits, classification, extraction

**Sonnet 5** (`claude-sonnet-5`) — everyday coding:
- Main development work
- Orchestrating multi-agent workflows
- Solid default when cost matters

**Opus 4.8** (`claude-opus-4-8`) — deep reasoning:
- Complex architectural decisions
- Research and analysis tasks
- Supports fast mode (/fast) for quicker output at full capability

**Fable 5** (`claude-fable-5`) — Mythos-class, above Opus:
- Hardest problems: subtle bugs, large refactors, ambiguous specs
- Long-horizon agentic work (use `[1m]` for the 1M context window)
- Default for main sessions; delegate down-tier for routine subagent work
