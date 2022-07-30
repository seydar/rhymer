require 'thesaurus'
require 'net/http'
require 'nokogiri'
require 'string_to_ipa'

VOWELS = %w[
a
ä
ɑ 
ɒ 
æ 
ɔ 
e
ə 
ɛ 
ɝ
i
ɪ 
ɨ 
o
ŏ
u
ʊ 
ŭ
ü
ʌ 
y
]

# TODO In #ipa and the main body, words are treated as having only one way to
# be pronounced. I should fix this in the future, when I'm better able to a)
# figure out which pronunciation is correct and b) scrape them from the website
# (which is available, but slightly more complex than I want to implement for
# this first iteration)

def synonyms(word)
  # Can swap out different thesauruses here 
  entries = Thesaurus.lookup word

  # there are so many more words we can use via `#words`, but let's not
  # overload the system just yet
  syns = entries.map {|e| e.root }

  # only take the one-word synonyms
  syns.filter {|w| w.split(/\s/).size == 1}
end

Website = URI "https://tophonetics.com/"

# FIXME this only gets Br*tish pronunciation. For some reason, I'm unable to
# get the site to return American pronunciation.
#
# FIXME What about when a word has different pronunciations? e.g. "read"
#def ipa(words)
#  p words
#  res = Net::HTTP.post_form Website, :text_to_transcribe => words.join(' '),
#                                     :output_dialect     => "am"
#  doc = Nokogiri::HTML res.body
#
#  ipa = doc.css ".transcribed_word"
#  ipas = ipa.children.map {|c| c.text }
#  p ipas.size
#  p words.size
#
#  #words = words.map.with_index {|w, i| [i, w] }
#  words.zip(ipas).to_h
#end

# Cannot for the life of me figure out why the commented-out query isn't working -- it's
# the original from the library! it works in small batches! what is going on?????
class StringToIpa::Phonetic
  def to_ipa
    #s = database.prepare("SELECT phonetic from phonetics where word = ?")
    #s.bind_params(@word.upcase)
    #p s.to_s
    phonetic = database.execute("select * from phonetics where word = \"#{@word.upcase}\"")

    if phonetic == []
      return @word
    else
      return phonetic[0]["phonetic"]
    end
  end
end

def ipa(words)
  words.map {|w| [w, w.to_ipa] }.to_h
end

def matching_from_start(word_1, word_2)
  num = 0
  [word_1.size, word_2.size].min.times do |i|
    num += 1 if word_1[i] == word_2[i]
  end

  num
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

def vowels(word)
  word.split(//).filter {|c| VOWELS.include? c }
end

def family_rhyme(word, corpus)
  best_match(word, corpus) {|w| vowels w }
end

input = "first" #STDIN.gets
syns = input.split(/\s+/).map do |w|
  # [[i, w], synonyms(w)]
  [w, ipa(synonyms(w))]
end.to_h

corpus = syns.keys + syns.values.flatten
ipas = ipa corpus

# match from one corpus to the others (no need to do full permutations, since
# if A matches B, and B matches C, we know that A will match C... but we don't
# know how many characters it will match. Hmmm...
def match_across_synonyms(*corpi)
  
end

require 'pry'
binding.pry

