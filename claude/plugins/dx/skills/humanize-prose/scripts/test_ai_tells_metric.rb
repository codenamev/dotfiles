#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Tests for ai_tells_metric. Run:  ruby test_ai_tells_metric.rb
#
# Stdlib only, no gems, no test framework. Every case here is a defect that
# actually shipped or was caught in review m-361, so a failure means a specific
# regression rather than a style complaint. The structural cases (fence indents,
# tilde fences, em-dash in a heading, a wrapped line opening on a year) are the
# ones that made the numbers wrong while the report still looked plausible.

require_relative "ai_tells_metric"

FAILURES = []
CHECKS = [0]

def check(label, actual, expected)
  CHECKS[0] += 1
  return if actual == expected

  FAILURES << "#{label}\n    expected: #{expected.inspect}\n    actual:   #{actual.inspect}"
end

def m(text)
  metrics(text)
end

# --- finding 1: character counts must see headings and table cells -------------

dash = "—"
check("em-dash in body", m("Plain body text#{dash}here.")[:em_dashes], 1)
check("em-dash in heading", m("## A heading#{dash}with one\n\nBody.")[:em_dashes], 1)
check("em-dash in table cell",
      m("| a | b |\n| --- | --- |\n| x#{dash}y | z |\n")[:em_dashes], 1)
check("em-dash in blockquote is not the author's",
      m("> Quoted#{dash}text\n\nBody.")[:em_dashes], 0)
check("em-dash in fenced code is not prose",
      m("```\nx = 1 #{dash} 2\n```\n\nBody.")[:em_dashes], 0)
check("smart quote in heading",
      m("## He said “no”\n\nBody.")[:smart_quotes], 2)
# The exact regression the reviewer reproduced: six em-dashes reported as zero.
six = <<~DOC
  ## Heading#{dash}one and#{dash}two

  | col#{dash}a | col#{dash}b |
  | --- | --- |

  > Quoted#{dash}here and#{dash}there

  Body text with none.
DOC
check("six em-dashes across heading/table/quote", m(six)[:em_dashes], 4)

# --- finding 2: fence indents and tilde fences --------------------------------

SLOP_IN_FENCE = "crucial seamless robust"
[0, 2, 3, 4, 6, 8].each do |indent|
  pad = " " * indent
  doc = "Body.\n\n#{pad}```\n#{pad}#{SLOP_IN_FENCE}\n#{pad}```\n"
  check("backtick fence at indent #{indent} is stripped",
        total(m(doc)[:ai_vocabulary]), 0)
end
[0, 1, 4].each do |indent|
  pad = " " * indent
  doc = "Body.\n\n#{pad}~~~\n#{pad}#{SLOP_IN_FENCE}\n#{pad}~~~\n"
  check("tilde fence at indent #{indent} is stripped",
        total(m(doc)[:ai_vocabulary]), 0)
end
check("fence nested in a list item is stripped",
      total(m("- Item:\n\n    ```\n    #{SLOP_IN_FENCE}\n    ```\n")[:ai_vocabulary]), 0)

# --- finding 5: abbreviations must not swallow real sentences -----------------

check("sentence ending in 'no' splits",
      split_sentences("The answer is no. We shipped it anyway. Nobody asked.").size, 3)
check("sentence ending in 'max' splits",
      split_sentences("Latency hit the max. Then it dropped. That was the fix.").size, 3)
check("'e.g.' does not split", split_sentences("See e.g. the retry path.").size, 1)
check("'etc.' before a capital does not split",
      split_sentences("Tests, docs, etc. Then we shipped.").size, 1)
check("'Dr.' does not split", split_sentences("Ask Dr. Reyes about it.").size, 1)
check("version numbers do not split", split_sentences("We pinned v0.1.0 exactly.").size, 1)
check("two plain sentences split", split_sentences("It broke. We fixed it.").size, 2)

# --- finding 9: a wrapped line opening on a year is not a list item -----------

wrapped = "We first saw this in the rollout of\n2024. Nobody had touched it since."
check("year at a wrapped line start stays in the prose",
      m(wrapped)[:words], words(wrapped.tr("\n", " ")).size)
check("real ordered list keeps its items separate",
      paragraphs("1. First item\n2. Second item\n").size, 1)
check("ordered list items are distinct units",
      paragraphs("1. First item\n2. Second item\n").first.size, 2)
check("wrapped bullet rejoins",
      paragraphs("- A bullet that wraps\n  onto a second line\n").first,
      ["A bullet that wraps onto a second line"])

# --- finding 10: snake_case survives emphasis stripping ----------------------

check("snake_case is not fused",
      strip_emphasis("Set the_flag_name and the_other_name").include?("the_flag_name"),
      true)
check("underscore emphasis still strips", strip_emphasis("a _word_ here"), "a word here")
check("asterisk emphasis still strips", strip_emphasis("a **word** here"), "a word here")

# --- finding 4: function words break phantom noun piles ----------------------

check("'plus' breaks a run",
      stacked_nouns(["Gemini auto-notes plus full transcript arrived"]), [])
check("real noun pile is still caught",
      stacked_nouns(["The customer onboarding flow latency budget regression hurt"]).size, 1)
check("inline-code placeholder does not manufacture a pile",
      m("The `a` `b` `c` `d` `e` values changed.")[:stacked_nouns], [])

# --- finding 7: scalar detectors carry their matches -------------------------

check("dash substitute reports a match", m("Policy -- announced late -- broke.")[:dash_substitutes].size, 2)
check("numeric range is visible for dismissal",
      m("Latency sat between 3 - 5 ms.")[:dash_substitutes].first.include?("3 - 5"), true)
check("triadic carries text", m("It is fast, cheap, and easy.")[:triadic].size, 1)
check("antithesis carries examples",
      m("It is text-to-speech, not speech-to-text.")[:antithesis_examples].empty?, false)

# --- cadence: the numbers this change exists to produce ----------------------

uniform = (["The cache holds the old copy here."] * 6).join(" ")
check("six same-length sentences give a uniform run of 6",
      m(uniform)[:lengths][:uniform_run], 6)
check("parataxis run is counted, and ends at the first long sentence",
      m("We shipped it. It broke. We rolled back. " \
        "Nobody noticed the regression until the following Tuesday afternoon.")[:lengths][:short_run], 3)
check("four short sentences give a run of 4",
      m("We shipped it. It broke. We rolled back. Nobody noticed.")[:lengths][:short_run], 4)
check("sample stdev matches the n-1 definition", stdev([2, 4, 4, 4, 5, 5, 7, 9]).round(4), 2.1381)
check("median of an even count is the midpoint", median([1, 2, 3, 4]), 2.5)
check("empty document reports no sentences", m("")[:lengths][:count], 0)

# --- hereditary-predicate contract for longest_run --------------------------

reference = lambda do |lengths, &pred|
  best = 0
  (0...lengths.size).each do |i|
    (i...lengths.size).each { |j| best = [best, j - i + 1].max if pred.call(lengths[i..j]) }
  end
  best
end
srand(20_260_730)
mismatches = 0
400.times do
  vec = Array.new(rand(0..12)) { rand(1..30) }
  spread = longest_run(vec) { |w| w.max - w.min <= 4 }
  short = longest_run(vec) { |w| w.all? { |n| n <= 5 } }
  mismatches += 1 unless spread == reference.call(vec) { |w| w.max - w.min <= 4 }
  mismatches += 1 unless short == reference.call(vec) { |w| w.all? { |n| n <= 5 } }
end
check("longest_run matches brute force over 400 random vectors", mismatches, 0)

# --- report renders without raising -----------------------------------------

check("report renders for an empty document", report(m("")).is_a?(String), true)
check("report renders for a rich document", report(m(six)).is_a?(String), true)

# --- summary ----------------------------------------------------------------

if FAILURES.empty?
  puts "ok: #{CHECKS[0]} checks passed"
  exit 0
else
  puts "FAILED #{FAILURES.size} of #{CHECKS[0]} checks\n"
  FAILURES.each { |f| puts "  - #{f}" }
  exit 1
end
