require 'thesaurus'
require 'string_to_ipa'
require './ipa.rb'

# I have no idea if there are diacritics in the IPA DB. If there are,
# then splitting based on "character" would be a mistake. Just FYI.

def synonyms(word)
  # Can swap out different thesauruses here 
  entries = Thesaurus.lookup word

  # there are so many more words we can use via `#words`, but let's not
  # overload the system just yet
  syns = entries.map {|e| e.root }

  # only take the one-word synonyms
  syns.filter {|w| w.split(/\s/).size == 1}
end

def ipa(words)
  words.map {|w| [w, w.to_ipa] }.to_h
end

def matching_from_start(word_1, word_2)
  i = 0
  until word_1[i] != word_2[i] || word_1[i].nil? || word_2[i].nil?
    i += 1
  end

  i
end

def best_match(word, corpus, &transform)
  transform ||= proc {|w| w }

  # Step 1: reverse the words so we can do sane string-matching
  w_r = transform[word].reverse
  cs  = corpus.map {|c| [c, transform[c].reverse] }

  # Step 2: see how many characters match for each word
  tally = {}
  cs.each do |c, c_r|
    num_matching = matching_from_start w_r, c_r
    tally[c] = num_matching
  end

  # Step 3: deliver the max
  tally.max[0]
end

def syllables(word)
  #vowels(word).size # naive
  word.split(/#{CONSONANTS}/).filter {|s| not s.empty? }.size
end

# what if the first character is a tick? then it starts with a :high
def meter(word)
  if word.include? "ˈ"
    [:low] + ([:high] * ((syllables(word) - 1) / 2)).join(:low)
  else
    ([:high] * (syllables(word) / 2)).join :low
  end
end

def vowels(word)
  word.split(//).filter {|c| VOWELS.include? c }
end

def family_rhyme(word, corpus)
  best_match(word, corpus) {|w| vowels w }
end

def correlate_synonyms(sentence, &transform)
  transform ||= proc {|w| w }

  syns = sentence.downcase.split(/\s+/).map do |w|
    [w, synonyms(w)] # limit the size for now
  end.to_h # {word => [word]}
  
  if syns.values.size <= 1
    plural = syns.values.size != 1
    raise "can only correlate multiple words (only #{syns.values.size} " +
          "word#{plural ? "s" : ""} provided)"
  end
  
  corpus = syns.keys + syns.values.flatten
  ipas   = ipa(corpus).map {|k, v| [k, transform[v]] }.to_h
  corpi  = syns.values

  combinations = corpi.reduce do |s, v|
    s.product v
  end

  # This matches **IPA**, not **spelling**. Took me a while to remember,
  # despite having written the code myself.
  combos = combinations.map do |words|
    pairs = words.map {|w| ipas[w] }.combination 2
    score = pairs.map {|w_1, w_2| matching_from_start w_1, w_2 }.min

    [words, score]
  end

  sorted = combos.sort_by {|ws, s| -s }
  #if sorted[0][0][0] == sorted[0][0][1]
  #  sorted[1]
  #else
  #  sorted[0]
  #end
end

#require 'pry'
#binding.pry

def alliterate(sentence)
  correlate_synonyms sentence
end

def family_rhyme(sentence)
  correlate_synonyms(sentence) {|w| vowels w.reverse }
end

def rhyme(sentence)
  correlate_synonyms(sentence) {|w| w.reverse }
end

# maybe have the secondary sort be by syllable length difference
# or have some kind of meter test
#phrase = ARGV.join(" ")
#puts "Family rhymes:"
#family_rhyme(phrase)[0..20].each {|ws| puts "\t#{ws}" }
#
#puts "Allterations:"
#alliterate(phrase)[0..20].each {|ws| puts "\t#{ws}" }
#
#puts "Rhymes:"
#rhyme(phrase)[0..20].each {|ws| puts "\t#{ws}" }

