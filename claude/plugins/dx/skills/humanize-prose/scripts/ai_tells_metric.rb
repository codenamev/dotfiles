#!/usr/bin/env ruby
# frozen_string_literal: true
#
# ai_tells_metric: count AI-tell signals in a prose/markdown file.
#
#   ruby ai_tells_metric.rb <path>
#
# Reports raw counts only. Interpretation (healthy ranges) lives in SKILL.md, so
# the script stays a measuring tape, not a judge.
#
# Everything is measured on *prose*: fenced code, inline code, headings, tables,
# link URLs and blockquotes are stripped first. An em-dash inside a code sample
# is not a prose tell, and a quoted paragraph is somebody else's voice.
#
# Stdlib only, no gems.

require "set"

# Written as escapes on purpose: the characters this script hunts for should not
# appear literally in it, or a grep for them lands here first.
EM_DASH = "—"
EN_DASH = "–"
SMART_QUOTES = ["“", "”", "‘", "’"].freeze

FIRST_PERSON = %w[I me Me my My].freeze
COLLABORATIVE = %w[we We our Our us Us].freeze

# Val's four, plus the intensifiers that pattern with them. Kept to adverbs that
# are almost never load-bearing, so a hit is nearly always a cut.
FILLER_INTENSIFIERS = %w[
  genuinely really truly actually incredibly remarkably deeply profoundly
  fundamentally extremely absolutely utterly vastly immensely notably
  significantly
].freeze

# Val named leverage / underscore / reflect. The rest are the same register, with
# the high-frequency verbs from Wikipedia's "Signs of AI writing" folded in.
# "reflect" has honest literal uses, so matches are printed for the human to
# dismiss rather than silently scored as errors.
CORPORATE_VERBS = %w[
  leverage leverages leveraging leveraged
  underscore underscores underscoring underscored
  reflect reflects reflecting
  utilize utilizes utilizing
  facilitate facilitates facilitating
  streamline streamlines streamlining
  showcase showcases showcasing
  foster fosters fostering
  harness harnesses harnessing
  empower empowers empowering
  spearhead spearheads spearheading
  unlock unlocks unlocking
  elevate elevates elevating
  delve delves delving
  enhance enhances enhancing enhanced
  garner garners garnered
  exemplify exemplifies embody embodies
  cement cements solidify solidifies
].freeze

# Adjectives and abstract nouns that spiked in post-2023 text. Same source.
AI_VOCABULARY = %w[
  crucial pivotal intricate intricacies vibrant tapestry testament interplay
  enduring profound groundbreaking seamless seamlessly holistic nuanced myriad
  multifaceted robust compelling invaluable unwavering meticulous meticulously
  landscape realm seismic transformative
].freeze

# Copula avoidance: an elaborate construction standing in for plain "is".
COPULA_DODGES = [
  "serves as", "serve as", "stands as", "stand as", "acts as", "act as",
  "functions as", "function as", "represents a", "represent a", "marks a",
  "constitutes a", "boasts", "boasting", "offers a", "positions itself as"
].freeze

# Participles tacked onto a clause to manufacture depth ("..., underscoring the
# community's connection to the land"). Restricted to the fake-depth set: a
# generic ", <verb>ing" scan fires on ordinary gerunds.
PARTICIPLE_TACKONS = %w[
  highlighting underscoring emphasizing ensuring reflecting symbolizing
  contributing cultivating fostering encompassing showcasing demonstrating
  illustrating signaling embodying cementing solidifying reinforcing affirming
  underlining
].freeze

# Phrases that claim to cut through to a deeper truth, and fake-candid hooks.
# Val's "rhetorical crutches", measured.
RHETORICAL_CRUTCHES = [
  "the real question is", "at its core", "in reality", "what really matters",
  "the deeper issue", "the heart of the matter", "let's be honest",
  "let's be real", "real talk", "the thing is",
  "let's dive in", "let's explore", "let's break this down",
  "here's what you need to know", "without further ado", "now let's look at",
  "what this really means"
].freeze

# The four voice patterns named in standing order 4. Its own text says the metric
# script detects none of them and they need conscious avoidance rather than a
# linter. Three of the four are phrase lists, so they are linted here; the fourth
# (throat-clearing) was already covered. The mechanism the order names is
# Goodhart's law on preference signals: length, hedging and visible self-awareness
# are cheap proxies for diligence, so they get rewarded and then optimised for.
#
# Telling the reader what to care about instead of letting them decide.
SIGNIFICANCE_CLAIMING = [
  "the part that matters", "the transferable part", "worth knowing",
  "what matters here", "the key insight", "the important thing",
  "the thing to understand", "the crucial point", "the real story",
  "the upshot", "more importantly", "most importantly",
  "which is the actual", "this is the actual"
].freeze

# Announcing directness in place of being direct.
HEDGED_EMPHASIS = [
  "to be explicit", "stated plainly", "put plainly", "plainly stated",
  "i want to be clear", "to be direct", "simply put", "in plain terms",
  "to put it plainly", "let me be direct", "to say it plainly",
  "to state it plainly"
].freeze

# Sycophancy aimed inward: visible self-criticism as a trust signal. Report the
# error, fix it, move on.
PERFORMATIVE_CONTRITION = [
  "i had it badly", "my mistake", "i apologize", "i apologise",
  "i should have caught", "i got this wrong", "embarrassingly",
  "i was wrong about", "mea culpa", "to my discredit", "i own that",
  "that was sloppy of me"
].freeze

# Ordinary claims dressed as reusable aphorisms.
APHORISM_FORMULAS = [
  "the language of", "the currency of", "the architecture of",
  "the grammar of", "the anatomy of", "the physics of", "becomes a trap",
  "is not a tool but", "is less about", "is really about"
].freeze

# Multi-word entries are matched with flexible internal whitespace.
HEDGES = [
  "arguably", "perhaps", "somewhat", "relatively", "fairly", "largely",
  "broadly", "generally", "typically", "essentially", "presumably",
  "seemingly", "ostensibly", "conceivably",
  "tends to", "tend to", "seems to", "seem to", "appears to", "appear to",
  "may well", "might well", "to some extent", "in some sense",
  "more or less", "it could be argued", "one could argue",
  "for the most part", "in a sense", "if anything"
].freeze

THROAT_CLEARING = [
  "worth noting", "worth flagging", "worth mentioning", "bears mentioning",
  "bears noting", "it is important to", "it's important to",
  "important to note", "to be clear", "let's be clear", "let me be clear",
  "here's the thing", "here is the thing", "the reality is",
  "the truth is", "make no mistake", "at the end of the day",
  "in many ways", "one thing to note", "needless to say",
  "that said", "having said that", "with that in mind"
].freeze

CLOSING_TICS = [
  "the takeaway", "that's the point", "that is the point",
  "the whole point", "that's the tell", "and that's exactly why",
  "which is exactly why", "this is why it matters", "in short",
  "in summary", "to sum up", "the bottom line", "all of which is to say",
  "what this means is"
].freeze

# Antithesis and its variants: corrective negation ("isn't X, it's Y") and bare
# contrasting pairs (", not Y"). One family, one counter.
# "rather than" and "instead of" were tried here and dropped: they fired 19 times
# on one shipped doc, almost all of them ordinary comparatives rather than the
# rhetorical shape Val is banning, and they drowned out the real hits.
ANTITHESIS_PATTERNS = {
  "not X but Y" => /\bnot (?:just |merely |only |simply )?[^.!?,;]{1,60}[,;]? but\b/i,
  "isn't X, it's Y" => /\b(?:is|are|was|were|isn't|aren't|wasn't|weren't|it's|that's)?\s*n[o']t\b[^.!?]{1,60}[.,;]\s*(?:it|that|they|this)(?:'s| is| are| was)\b/i,
  ", not Y" => /,\s*not\b(?! only)(?! just)/i,
  "less X, more Y" => /\bless\b[^.!?,]{1,40},\s*more\b/i
}.freeze

NEGATIVE_OPENERS = %w[no not never nor neither none nothing].freeze

# Suffix scan. Deliberately crude: it over-fires on words that are simply the
# right noun in technical prose, so the report prints the offenders and a rate
# rather than pretending the count is a verdict.
NOMINALIZATION_RE =
  /\b[a-z]{3,}(?:tions?|sions?|ments?|ances?|ences?|ities|ity|ness|isms?|izations?)\b/i

# Lexicalized nouns with no idiomatic verb or adjective to swap back to.
NOMINALIZATION_SKIP = %w[
  environment environments document documents moment moments component
  components instrument instruments argument arguments element elements comment
  comments department departments government equipment entity entities
  community communities city cities quantity quantities question questions
  mention mentions attention intention intentions convention conventions
  session sessions version versions permission permissions dimension
  dimensions extension extensions expression expressions function functions
  option options section sections condition conditions connection connections
  position positions direction directions distinction distinctions exception
  exceptions description descriptions action actions reaction reactions
  collection collections definition definitions repetition business witness
  harness assessment cadence sentence sentences instance instances balance
  distance distances difference differences reference references preference
  preferences evidence sequence sequences audience audiences experience
  experiences maintenance presence absence guidance consequence consequences
  chance chances advance advances
].to_set.freeze

# Function words. English rarely sustains five content words without one, so a
# run that long is usually a noun pile ("customer onboarding flow latency
# budget"). Four-word runs were tried and abandoned: with no part-of-speech
# tagging, verbs and adverbs slip in ("Meanwhile working skills move") and the
# detector fired 25 times on one shipped doc with almost nothing true.
FUNCTION_WORDS = %w[
  a an the and or but nor so yet for of in on at to from by with without into
  onto over under about after before between through during against across per
  via than as if when while where that which who whom whose what why how this
  these those it its he she they them their we our us i me my you your is are
  was were be been being am do does did have has had will would can could
  should may might must shall not no there here then now just only also very
  too all any both each more most some such own same up out off down again once
  because until unless since though although whether either neither one two
  three cannot can't won't don't doesn't didn't isn't aren't wasn't weren't
  hasn't haven't hadn't wouldn't couldn't shouldn't it's that's there's let's
  plus minus versus like among toward towards upon within beyond behind besides
  despite except throughout along around below above even many few several
  other another every
  code
].freeze

# Openers too common to count as anaphora when a paragraph repeats them.
BLAND_OPENERS = %w[the a an it this that there these i we].freeze

# Abbreviations that end in a period without ending a sentence.
#
# Deliberately short. This set only does work when the following word is
# capitalized, because the lowercase-or-digit tail check in split_sentences
# already covers "e.g. the", "Fig. 3" and "v0.1.0" without any list. That makes
# every entry which is also an ordinary English word a net loss: "The answer is
# no. We shipped it anyway." merged into one sentence, which raises the mean,
# hides a short run, and pushes CV toward the range that reads as healthy. Dropped
# for that reason: no, min, max, co, st, ca, sd, eq, resp, approx, fig, avg.
# What earns a place: titles, company suffixes, and forms always written with dots.
ABBREVIATIONS = %w[
  e.g i.e etc vs cf al mr mrs ms dr prof sr jr inc ltd
].freeze

BUCKETS = [[1, 5], [6, 10], [11, 15], [16, 20], [21, 30], [31, nil]].freeze

# Ordered markers are capped at two digits. Unbounded, a hard-wrapped line opening
# on a year read as a list item: "...the rollout of\n2024. Nobody had touched it"
# split in two and dropped the year from the prose entirely. Real ordered lists in
# our docs never reach 100 items.
LIST_MARKER_RE = /\A\s*(?:[-*+]|\d{1,2}[.)])\s+/
NOT_NOUN_RE = /(?:ly|ed)\z/i

# Each slot may be multi-word ("the cost, the value, and the decision"). Slots
# are capped at four words: uncapped, the pattern swallowed whole clauses and
# scored any compound sentence as a triad, reading 36 on one shipped doc against
# a stated healthy range of 0-2. Capping targets the actual tell, a list of three
# short phrases, and costs only the occasional long triad.
# Known over-counts that remain: an introductory clause before a two-item "X and
# Y" ("However, foo and bar"), and a two-clause sentence whose halves happen to
# be short. Advisory signal, so this is left as acceptable noise rather than
# anchored out with brittle opener lists.
TRIAD_SLOT = "\\w[\\w'-]*(?: \\w[\\w'-]*){0,3}"
TRIADIC_RE = /\b#{TRIAD_SLOT}, #{TRIAD_SLOT},? and #{TRIAD_SLOT}\b/

# ", no guessing." / ", no wasted motion." A clipped negation used as a closer
# instead of written out as a clause.
TAILING_NEGATION_RE = /,\s+no\s+[\w-]+(?:\s+[\w-]+)?\s*[.!?]/i
# ASCII stand-ins people reach for once the real em-dash is banned.
DASH_SUBSTITUTE_RE = /\s--?\s/

# Phrase matching tolerates any run of whitespace between words, so a
# hard-wrapped "worth\nnoting" still counts once lines are rejoined.
def phrase_re(phrase)
  /\b#{phrase.split(/\s+/).map { |w| Regexp.escape(w) }.join('\s+')}\b/i
end

VOCAB_RE = (
  FILLER_INTENSIFIERS + CORPORATE_VERBS + AI_VOCABULARY + HEDGES +
  THROAT_CLEARING + CLOSING_TICS + COPULA_DODGES + RHETORICAL_CRUTCHES +
  APHORISM_FORMULAS + SIGNIFICANCE_CLAIMING + HEDGED_EMPHASIS +
  PERFORMATIVE_CONTRITION
).each_with_object({}) { |w, h| h[w] = phrase_re(w) }.freeze

# A tacked-on participle only counts after a comma; that is what makes it a
# tack-on rather than an ordinary gerund subject.
PARTICIPLE_RE = PARTICIPLE_TACKONS
                .each_with_object({}) { |w, h| h[w] = /,\s+#{w}\b/i }.freeze

# Case-sensitive on purpose: "I" is a pronoun, "i" is an index variable.
CASED_RE = (FIRST_PERSON + COLLABORATIVE)
           .each_with_object({}) { |w, h| h[w] = /\b#{Regexp.escape(w)}\b/ }.freeze

# Fences are matched with the indent hoisted out of the alternation. Written as
# `(?: {0,3}```|~~~)` the bound applied only to the backtick branch, so a tilde
# fence indented by one space and any fence indented four or more (which is what
# a fence nested in a list item looks like) went unstripped and its contents were
# counted as prose. The bound of 9 covers two levels of list nesting in our docs.
FENCE_RE = /^ {0,9}(?:```|~~~).*?^ {0,9}(?:```|~~~)[^\n]*$/m

# Tier one: remove what the author did not write as running prose. Code is not
# prose, and a blockquote is somebody else's voice. Headings and table cells
# survive, because those ARE the author's prose and the character-level counts
# have to see them. Stripping them cost the em-dash rule its teeth: a draft with
# an em-dash in every heading scored 0 and passed clean.
#
# List markers and line breaks survive too: paragraphs needs them to tell a
# hard-wrapped continuation line from the start of a new list item.
#
# Indented code blocks (four spaces, no fence) are deliberately not stripped.
# Every doc we write fences its code, and a 4-space indent is far more often a
# nested bullet, so the rule cost more real prose than it saved.
def strip_nonprose(content)
  text = content.sub(/\A---\n.*?\n---\n/m, "")               # frontmatter
  text = text.gsub(FENCE_RE, "")                             # fenced code
  text = text.gsub(/<!--.*?-->/m, "")
  text = text.gsub(/`[^`\n]*`/, "code")                      # inline code -> bland noun
  text = text.gsub(/^\s*>.*$/, "")                           # blockquotes
  text = text.gsub(/^\s*[-*_]{3,}\s*$/, "")                  # horizontal rules
  text = text.gsub(/!?\[([^\]]*)\]\([^)]*\)/, '\1')          # links -> label
  strip_emphasis(text)
end

# Underscore emphasis needs non-word neighbours or snake_case identifiers written
# without backticks get fused ("the_flag_name" -> "theflagname").
def strip_emphasis(text)
  text = text.gsub(/\*{1,3}(\S(?:.*?\S)?)\*{1,3}/, '\1')
  text.gsub(/(?<![A-Za-z0-9_])_{1,3}(\S(?:.*?\S)?)_{1,3}(?![A-Za-z0-9_])/, '\1')
end

# Tier two: additionally remove the scaffolding that would wreck sentence
# segmentation and the vocabulary scans. A heading is a fragment rather than a
# sentence, and a table row is a grid rather than a clause.
def to_prose(text)
  text = text.gsub(/^\s*\#{1,6} .*$/, "")                    # headings
  text.gsub(/^\s*\|.*$/, "")                                 # table rows
end

# List markers removed, headings and tables kept. This is what the character-level
# counts run on. Markers have to go or every bullet reads as a " - " dash
# substitute.
def countable(scaffolded)
  scaffolded.each_line.map { |line| line.sub(LIST_MARKER_RE, "") }.join
end

# Blank-line separated blocks, unwrapped into logical units.
#
# Markdown is hard-wrapped, so a continuation line is joined to the unit above
# it. A line opening on a list marker starts a new unit instead: a bullet list
# with no terminal punctuation would otherwise read as one enormous sentence.
def paragraphs(prose)
  prose.split(/\n\s*\n/).filter_map do |block|
    units = []
    block.each_line do |raw|
      line = raw.strip
      next if line.empty?

      if raw.match?(LIST_MARKER_RE) || units.empty?
        units << raw.sub(LIST_MARKER_RE, "").strip
      else
        units[-1] = "#{units[-1]} #{line}"
      end
    end
    units unless units.empty?
  end
end

# Split one line into sentences, keeping abbreviations and decimals whole.
def split_sentences(line)
  out = []
  start = 0
  offset = 0
  while (m = /[.!?]+(?=[\s"')\]]|\z)/.match(line, offset))
    offset = m.end(0)
    preceding = line[start...m.begin(0)]
    last_word = preceding[/([A-Za-z.]+)\z/, 1]
    next if last_word && ABBREVIATIONS.include?(last_word.downcase.delete_suffix("."))

    tail = line[m.end(0)..] || ""
    next if !tail.strip.empty? && tail.match?(/\A\s*[a-z0-9]/) # 0.1.0, foo.py, ellipsis

    head = line[start...m.end(0)].strip
    out << head unless head.empty?
    start = m.end(0)
  end
  rest = (line[start..] || "").strip
  out << rest unless rest.empty?
  out
end

def words(text)
  text.scan(/[A-Za-z][A-Za-z'-]*/)
end

# Matches plus a window of surrounding text. A bare ` -- ` match tells the reader
# nothing; "Latency sat between 3 - 5 ms" tells them it is a numeric range and
# they can dismiss it without grepping the document by hand.
def matches_with_context(text, regexp, pad = 18)
  out = []
  offset = 0
  while (m = regexp.match(text, offset))
    offset = m.end(0) > m.begin(0) ? m.end(0) : m.begin(0) + 1
    lo = [m.begin(0) - pad, 0].max
    hi = [m.end(0) + pad, text.length].min
    snippet = text[lo...hi].gsub(/\s+/, " ").strip
    # Snap to word boundaries. A window that opens mid-word ("ency sat between")
    # is harder to read than no window at all.
    snippet = snippet.sub(/\A\S*\s+/, "") if lo.positive? && text[lo - 1].match?(/\S/)
    snippet = snippet.sub(/\s+\S*\z/, "") if hi < text.length && text[hi].match?(/\S/)
    out << snippet unless snippet.empty?
  end
  out
end

def tally(vocab, text)
  vocab.each_with_object({}) do |w, h|
    n = text.scan(VOCAB_RE[w]).size
    h[w] = n if n.positive?
  end
end

# Longest consecutive stretch for which the block holds over the window.
#
# The two-pointer scan is only valid for a HEREDITARY predicate, meaning every
# subwindow of a passing window also passes. Both current predicates qualify
# (a spread bound and an all-elements bound). A predicate over an aggregate, such
# as a mean or a proportion, does not, and would silently return wrong answers
# here rather than failing. Check that property before adding a caller.
def longest_run(lengths)
  best = 0
  start = 0
  lengths.each_index do |finish|
    start += 1 while start <= finish && !yield(lengths[start..finish])
    best = [best, finish - start + 1].max
  end
  best
end

def mean(values)
  values.sum.to_f / values.size
end

def median(values)
  sorted = values.sort
  mid = sorted.size / 2
  sorted.size.odd? ? sorted[mid].to_f : (sorted[mid - 1] + sorted[mid]) / 2.0
end

# Sample standard deviation (n-1), matching Python's statistics.stdev.
def stdev(values)
  return 0.0 if values.size < 2

  m = mean(values)
  Math.sqrt(values.sum { |v| (v - m)**2 } / (values.size - 1).to_f)
end

def length_stats(lengths)
  return { count: 0 } if lengths.empty?

  sd = stdev(lengths)
  avg = mean(lengths)
  {
    count: lengths.size,
    mean: avg,
    median: median(lengths),
    sd: sd,
    cv: avg.zero? ? 0.0 : sd / avg,
    min: lengths.min,
    max: lengths.max,
    buckets: BUCKETS.map do |lo, hi|
      [lo, hi, lengths.count { |n| n >= lo && (hi.nil? || n <= hi) }]
    end,
    uniform_run: longest_run(lengths) { |win| win.max - win.min <= 4 },
    short_run: longest_run(lengths) { |win| win.all? { |n| n <= 5 } }
  }
end

# Longest stretch of consecutive sentences opening on a negation.
def negative_opener_run(para_sents)
  para_sents.map do |sents|
    best = 0
    run = 0
    sents.each do |s|
      first = words(s).first
      if first && NEGATIVE_OPENERS.include?(first.downcase)
        run += 1
        best = [best, run].max
      else
        run = 0
      end
    end
    best
  end.max || 0
end

# Sentences in a paragraph that reuse an earlier sentence's opening word.
def repeated_openers(para_sents)
  para_sents.sum do |sents|
    seen = Hash.new(0)
    sents.each do |s|
      first = words(s).first
      next unless first

      w = first.downcase
      next if BLAND_OPENERS.include?(w)

      seen[w] += 1
    end
    seen.values.sum { |n| n > 1 ? n - 1 : 0 }
  end
end

# Runs of content words with no function word between them.
#
# Over-fires by roughly half on real prose, which is why the report prints the
# matches. An all-capitalized run is skipped as a proper-noun chain.
def stacked_nouns(sentences, min_run = 5)
  found = []
  flush = lambda do |run|
    return if run.size < min_run
    return if run.all? { |w| w[0] == w[0].upcase && w[0].match?(/[A-Za-z]/) }

    found << run.join(" ")
  end

  sentences.each do |s|
    run = []
    s.scan(/[A-Za-z][A-Za-z'-]*|[^\sA-Za-z]/) do |tok|
      low = tok.downcase
      if tok[0].match?(/[A-Za-z]/) && !FUNCTION_WORDS.include?(low) && !NOT_NOUN_RE.match?(low)
        run << tok
        next
      end
      flush.call(run)
      run = []
    end
    flush.call(run)
  end
  found
end

def nominalizations(prose)
  prose.scan(NOMINALIZATION_RE).each_with_object(Hash.new(0)) do |w, h|
    low = w.downcase
    h[low] += 1 unless NOMINALIZATION_SKIP.include?(low)
  end
end

# Return the AI-tell signal counts for a block of text.
def metrics(content)
  scaffolded = strip_nonprose(content)
  counted = countable(scaffolded)
  para_units = paragraphs(to_prose(scaffolded))
  para_sents = para_units.map { |units| units.flat_map { |u| split_sentences(u) } }
  sents = para_sents.flatten
  lengths = sents.map { |s| words(s).size }.reject(&:zero?)
  # Unwrapped: one unit per line, so a phrase detector can match across a
  # hard-wrapped sentence but never across two bullets.
  prose = para_units.flatten.join("\n")

  {
    words: words(prose).size,
    # Not a strict subset: inline code collapses to the word "code", which can add
    # a token the raw text never had ("`42`" counts 0 raw and 1 prose.)
    raw_words: words(content).size,
    # Character-level counts run on `counted`, which keeps headings and table
    # cells. Everything else runs on `prose`.
    em_dashes: counted.scan(EM_DASH).size,
    en_dashes: counted.scan(EN_DASH).size,
    smart_quotes: SMART_QUOTES.sum { |c| counted.scan(c).size },
    dash_substitutes: matches_with_context(counted, DASH_SUBSTITUTE_RE),
    triadic: prose.scan(TRIADIC_RE),
    first_person: FIRST_PERSON.sum { |w| prose.scan(CASED_RE[w]).size },
    collaborative: COLLABORATIVE.sum { |w| prose.scan(CASED_RE[w]).size },
    intensifiers: tally(FILLER_INTENSIFIERS, prose),
    corporate_verbs: tally(CORPORATE_VERBS, prose),
    ai_vocabulary: tally(AI_VOCABULARY, prose),
    hedges: tally(HEDGES, prose),
    copula_dodges: tally(COPULA_DODGES, prose),
    throat_clearing: tally(THROAT_CLEARING, prose),
    rhetorical_crutches: tally(RHETORICAL_CRUTCHES, prose),
    aphorisms: tally(APHORISM_FORMULAS, prose),
    closing_tics: tally(CLOSING_TICS, prose),
    nominalizations: nominalizations(prose),
    stacked_nouns: stacked_nouns(sents),
    participle_tackons: PARTICIPLE_TACKONS.each_with_object({}) { |w, h|
      n = prose.scan(PARTICIPLE_RE[w]).size
      h[w] = n if n.positive?
    },
    tailing_negations: prose.scan(TAILING_NEGATION_RE),
    antithesis: ANTITHESIS_PATTERNS.each_with_object({}) { |(name, rx), h|
      n = prose.scan(rx).size
      h[name] = n if n.positive?
    },
    # The highest-volume detector in the set, and finding 6 of review m-361 turns
    # on being able to see the hits: a disambiguating "X, not Y" is load-bearing
    # while a cadence "X, not Y" is the tell, and only the text distinguishes them.
    antithesis_examples: ANTITHESIS_PATTERNS.values
                                            .flat_map { |rx| matches_with_context(prose, rx, 12) },
    negative_opener_run: negative_opener_run(para_sents),
    repeated_openers: repeated_openers(para_sents),
    rhetorical_questions: sents.count { |s| s.rstrip.end_with?("?") },
    significance_claiming: tally(SIGNIFICANCE_CLAIMING, prose),
    hedged_emphasis: tally(HEDGED_EMPHASIS, prose),
    performative_contrition: tally(PERFORMATIVE_CONTRITION, prose),
    lengths: length_stats(lengths),
    # Volume. Standing order 4 says the failure being guarded against is not bad
    # grammar, it is volume, and that a pass which makes a document longer was
    # applied cosmetically. Nothing else in this script measures that, and none of
    # the 23 prose constraints it enforces mentions length at all.
    bullet_lines: bullet_and_body_lines(to_prose(scaffolded))[0],
    body_lines: bullet_and_body_lines(to_prose(scaffolded))[1],
    para_sentence_counts: para_sents.map(&:size).reject(&:zero?)
  }
end

# Bullet lines versus other non-empty lines. A high ratio is the "bullet wall" the
# platform legates' messaging prompt bans outright.
def bullet_and_body_lines(prose)
  bullets = 0
  body = 0
  prose.each_line do |line|
    next if line.strip.empty?

    line.match?(LIST_MARKER_RE) ? bullets += 1 : body += 1
  end
  [bullets, body]
end

def per100(count, total)
  total.zero? ? 0.0 : 100.0 * count / total
end

def hits(counts, limit = 6)
  return "" if counts.empty?

  top = counts.sort_by { |w, n| [-n, w] }.first(limit)
  shown = top.map { |w, n| n == 1 ? w : "#{w} #{n}" }.join(", ")
  extra = counts.size - top.size
  "   (#{shown}#{extra.positive? ? ", +#{extra} more" : ''})"
end

def total(counts)
  counts.values.sum
end

# Continuation line of sample matches, for the detectors whose count alone gives
# the reader nothing to act on.
def samples(list, limit = 3, width = 52)
  return [] if list.empty?

  shown = list.uniq.first(limit).map { |s| s.length > width ? "#{s[0, width - 1]}…" : s }
  ["      e.g. #{shown.map(&:inspect).join('; ')}"]
end

def report(m)
  words_count = m[:words]
  out = []
  out << "prose words: #{words_count} of #{m[:raw_words]} in the file"
  out << "  (code and blockquotes are excluded everywhere; headings and table"
  out << "   cells count toward the character tells but not the word or"
  out << "   sentence totals)"

  out << ""
  out << "Mechanical"
  out << "  em-dashes: #{m[:em_dashes]}"
  out << "  en-dashes: #{m[:en_dashes]}"
  out << "  smart quotes: #{m[:smart_quotes]}"
  out << "  dash substitutes ( -- / - ): #{m[:dash_substitutes].size}"
  out.concat(samples(m[:dash_substitutes]))
  [["filler intensifiers", :intensifiers],
   ["corporate-register verbs", :corporate_verbs],
   ["AI vocabulary (adj / abstract noun)", :ai_vocabulary],
   ["hedging qualifiers", :hedges],
   ["copula avoidance (says X, means is)", :copula_dodges]].each do |label, key|
    out << "  #{label}: #{total(m[key])}#{hits(m[key])}"
  end
  nom = m[:nominalizations]
  out << format("  nominalization: %d (%.1f per 100 words)%s",
                total(nom), per100(total(nom), words_count), hits(nom))
  stacked = m[:stacked_nouns]
  suffix = stacked.empty? ? "" : "   (#{stacked.first(4).map(&:inspect).join('; ')})"
  out << "  stacked noun phrases: #{stacked.size}#{suffix}"
  part = m[:participle_tackons]
  out << "  participial tack-ons (', underscoring...'): #{total(part)}#{hits(part)}"

  out << ""
  out << "Rhetorical shape"
  out << %(  rule of three (", X, Y, and Z"): #{m[:triadic].size})
  out.concat(samples(m[:triadic]))
  ant = m[:antithesis]
  out << "  antithesis / corrective negation: #{total(ant)}#{hits(ant)}"
  out.concat(samples(m[:antithesis_examples]))
  out << "  tailing negations (', no guessing.'): #{m[:tailing_negations].size}"
  out.concat(samples(m[:tailing_negations]))
  out << "  longest negative-opener run: #{m[:negative_opener_run]} sentences"
  out << "  repeated sentence openers within a paragraph: #{m[:repeated_openers]}"
  out << "  rhetorical questions: #{m[:rhetorical_questions]}"
  [["throat-clearing openers", :throat_clearing],
   ["rhetorical crutches", :rhetorical_crutches],
   ["aphorism formulas", :aphorisms],
   ["closing / landing tics", :closing_tics],
   ["significance-claiming", :significance_claiming],
   ["hedged emphasis", :hedged_emphasis],
   ["performative contrition", :performative_contrition]].each do |label, key|
    out << "  #{label}: #{total(m[key])}#{hits(m[key])}"
  end

  out << ""
  out << "Volume"
  bullets = m[:bullet_lines]
  body = m[:body_lines]
  share = (bullets + body).zero? ? 0.0 : 100.0 * bullets / (bullets + body)
  out << format("  bullet lines: %d of %d (%.0f%% of the document)", bullets, bullets + body, share)
  paras = m[:para_sentence_counts]
  if paras.empty?
    out << "  paragraphs: 0"
  else
    walls = paras.count { |n| n > 4 }
    out << format("  paragraphs: %d, mean %.1f sentences, longest %d",
                  paras.size, mean(paras), paras.max)
    out << "  paragraphs over 4 sentences: #{walls}"
  end

  out << ""
  out << "Cadence"
  len = m[:lengths]
  if len[:count].zero?
    out << "  no sentences found"
  else
    out << "  sentences: #{len[:count]}"
    # median prints to one decimal: an even sentence count gives a genuine .5,
    # and rounding it away hid a real half-word difference between two drafts.
    out << format("  length: mean %.1f, median %.1f, sd %.1f, CV %.2f, range %d-%d",
                  len[:mean], len[:median], len[:sd], len[:cv], len[:min], len[:max])
    widest = [len[:buckets].map(&:last).max, 1].max
    len[:buckets].each do |lo, hi, n|
      span = hi.nil? ? "#{lo}+" : "#{lo}-#{hi}"
      out << format("    %6s words: %4d  %s", span, n, "#" * (24.0 * n / widest).round)
    end
    out << "  longest uniform run (lengths within 4 words): #{len[:uniform_run]} sentences"
    out << "  longest short-sentence run (5 words or fewer): #{len[:short_run]} sentences"
  end

  out << ""
  out << "Voice"
  out << "  first-person (writer-voice): #{m[:first_person]}"
  out << "  collaborative (we/our/us): #{m[:collaborative]}"
  out.join("\n")
end

USAGE = <<~TEXT
  usage: ai_tells_metric.rb <path>

  Counts the mechanically-detectable AI tells in a markdown or text file, grouped
  as Mechanical (dashes and their ASCII stand-ins, smart quotes, filler
  intensifiers, corporate-register verbs, AI vocabulary, hedging qualifiers,
  copula avoidance, nominalization, stacked noun phrases, participial tack-ons),
  Rhetorical shape (rule of three, antithesis and corrective negation, tailing
  negations, negative-opener runs, repeated sentence openers, rhetorical
  questions, throat-clearing, rhetorical crutches, aphorism formulas, closing
  tics), Cadence (sentence-length distribution, standard deviation, coefficient of
  variation, longest uniform run) and Voice (pronoun use).

  Fenced and inline code, headings, tables, link URLs and blockquotes are stripped
  before counting, so the numbers describe prose the author wrote.

  Counts are advisory and several detectors over-fire by design, printing their
  matches so a human can dismiss them. The judgment tells humanize-prose also
  strips (paragraph pinning, setup/payoff, summary beats, performed enthusiasm,
  spoken voice) are not measurable here and are left to human review.
TEXT

def main(argv)
  if argv.any? { |a| ["-h", "--help"].include?(a) }
    puts USAGE
    return 0
  end
  if argv.empty?
    warn USAGE
    return 2
  end

  path = argv[0]
  begin
    content = File.read(path, encoding: "UTF-8")
  rescue SystemCallError, IOError => e
    warn "ai_tells_metric: cannot read #{path.inspect}: #{e.message}"
    return 2
  end
  unless content.valid_encoding?
    warn "ai_tells_metric: #{path.inspect} is not valid UTF-8"
    return 2
  end

  puts report(metrics(content))
  0
end

exit(main(ARGV)) if $PROGRAM_NAME == __FILE__
