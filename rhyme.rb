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

# Split will normally remove the delimiter.
# By using a regex with look-behind (?<=), we keep the delimiter
# and maintain it with one of the splittings (as opposed to leaving it
# on its own)
#
# Clever trick learned from stack overflow.
#
# In addition, simply capturing the match with () is enough to keep the
# delimiter, but it won't be part of any split group and will be separate
#
# Here, we make use of both of those tricks
def syllables(word)
  return [] if vowels(word).empty?

  word.split(/(#{DIPHTHONGS.join '|'})/).map do |part|
    if part =~ /#{DIPHTHONGS.join '|'}/
      part
    else
      part.split(/(?<=#{VOWELS.join '|'})/).filter {|s| not s.empty? }
    end
  end.flatten.reduce [] do |parts, syl|
    if parts.empty?
      [syl]
    elsif vowels(parts[-1]).empty? or vowels(syl).empty?
      parts[-1] = parts[-1] + syl
      parts
    else
      parts << syl
    end
  end
end

# Oddballs this fails on:
#   incorrigible
#   
# How to deal with dactylic words?
def meter(word)
  word.gsub /^[ˈ]+/, '' # in case the word begins with a tick

  # If the stress comes in the middle of the word,
  # we know that immediately after it will be a `:high` and
  # immediately before it will be a `:low`, so fudge the meter until
  # you get the flow that works.
  if word.include? "ˈ"
    first, last = word.split "ˈ"

    # The invariant here is that it will begin with `:high`
    sylls = syllables(last).size
    met_last = if sylls.even?
                 [:high, :low] * (sylls / 2)
               else
                 [:high] + [:low, :high] * (sylls / 2)
               end

    # The invariant here is that it will end with `:low`
    sylls = syllables(first).size
    met_first = if sylls.even?
                  [:high, :low] * (sylls / 2)
                else
                  [:low] + [:high, :low] * (sylls / 2)
                end

    met_first + met_last
  else
    # Else pretend that the stress is word-initial
    sylls = syllables(word).size
    if sylls.even?
      [:high, :low] * (sylls / 2)
    else
      [:high] + [:low, :high] * (sylls / 2)
    end
  end
end

# This should somehow pay attention to syllable boundaries
def vowels(word)
  #word.split(//).filter {|c| VOWELS.include? c }
  word.split(/(#{DIPHTHONGS.join '|'})/).map do |part|
    if part =~ /#{DIPHTHONGS.join '|'}/
      part
    else
      part.split(/(?<=#{VOWELS.join '|'})/).filter {|s| not s.empty? }
    end
  end.flatten
     .map    {|part| part.gsub /[^#{VOWELS}]+/, '' }
     .filter {|s| not s.empty? }
end

def correlate_synonyms(sentence, &transform)
  transform ||= proc {|w| w }

  syns = sentence.downcase.split(/\s+/).map do |w|
    [w, synonyms(w)]
  end.to_h # {word => [word]}
  
  if syns.values.size <= 1
    plural = syns.values.size != 1
    raise "can only correlate multiple words (only #{syns.values.size} " +
          "word#{plural ? "s" : ""} provided)"
  end
  
  corpus = syns.keys + syns.values.flatten
  ipas   = ipa corpus
  meters = corpus.map {|w| [w, meter(ipas[w])] }.to_h
  corpi  = syns.values

  combinations = corpi.reduce do |s, v|
    s.product v
  end.map {|ws| ws.flatten }

  # This matches **IPA**, not **spelling**. Took me a while to remember,
  # despite having written the code myself.
  combos = combinations.map do |words|
    if words.uniq.size != words.size
      # if any duplicate words, -(-1) will be the highest score
      # and thus the biggest loser
      [words, [-1], [-1]] 
    else

      metering_well = words.each_cons(2).map do |w_1, w_2|
        # Metering only makes sense if the word is coming in the normal
        # way. Any alteration wouldn't make sense for English metering
        if meters[w_1].last != meters[w_2].first
          1 # true. Using a number to aid in sorting
        else
          0 # false. Using a number to aid in sorting
        end
      end

      [words, metering_well]
    end
  end

  combos = combos.filter {|ws, o| o.sum == ws.size - 1 }.map do |words, o|
    # This looks at all combos of words (two at a time) and checks their distances
    pairs = words.map {|w| transform[ipas[w]] }.combination 2
    #pairs = words.map {|w| transform[ipas[w]] }.each_cons 2 # only look at adjacent words
    scores = pairs.map {|w_1, w_2| matching_from_start w_1, w_2 }

    [words, scores, o]
  end

  sorted = combos.sort_by {|ws, s, o| [-(s.min), -(o.sum)] }
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
  correlate_synonyms(sentence) do |word|
    syllables(word).map {|syl| syl.gsub /[^#{VOWELS}]+/, ''  }
  end
end

def rhyme(sentence)
  correlate_synonyms(sentence) {|w| w.reverse }
end

def syllable_length(sentence)
  matches = alliterate(sentence)[0..20]
  matches.map do |ws, s|
    syllable_difference = ws[1..-1].reduce([0, ws[0]]) do |(sum, w_p), w|
      [sum + (syllables(w_p.to_ipa).size - syllables(w.to_ipa).size).abs, w]
    end[0]
    [ws, s, syllable_difference]
  end.sort_by {|(ws, s, d)| [s, d] }
end

if __FILE__ == $0

  # maybe have the secondary sort be by syllable length difference
  # or have some kind of meter test
  phrase = ARGV.join(" ")
  puts "Family rhymes:"
  family_rhyme(phrase)[0..20].each {|ws| puts "\t#{ws}" }
  
  puts "Allterations:"
  alliterate(phrase)[0..20].each {|ws| puts "\t#{ws}" }
  
  puts "Rhymes:"
  rhyme(phrase)[0..20].each {|ws| puts "\t#{ws}" }
  
  puts "Rhymes but pay attention to syllables:"
  syllable_length(phrase)[0..20].each {|ws| puts "\t#{ws}" }
end

