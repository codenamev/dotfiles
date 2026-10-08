## Model Selection Strategy

**Haiku 5.5** (`claude-haiku-5-5`), $0.10/$0.50:
- Classification, extraction, mechanical edits
- High-volume workers with checkable output

**Sonnet 5.5** (`claude-sonnet-5-5`), $2/$10:
- Routine spin-off lanes and everyday coding
- Read-only subagents (Explore, search, summarizing)

**Opus 5.5** (`claude-opus-5-5`), $4/$20:
- Management, Review and money-path lanes
- Design decisions, hard debugging, research
- Default for main sessions (`opus[1m]`)

**Fable 5.1** (`claude-fable-5-1`), $10/$50:
- Only when Opus 5.5 at high effort falls short
- Long-horizon work where a miss is expensive
