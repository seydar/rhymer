require 'string_to_ipa'

class StringToIpa::Phonetic
  def self.database
    @@database
  end

  def to_ipa
    # No idea why this shitty hack is sometimes required
    phonetic = database.execute("SELECT phonetic from phonetics where word = \"#{@word.upcase}\"")

    # Changed for my purposes
    if phonetic == []
      return "" #@word
    else
      return phonetic[0]["phonetic"]
    end
  end
end

DIPHTHONGS = ["eɪ", "oʊ", "aʊ", "ɪə", "eə", "ɔɪ", "aɪ", "ʊə"]

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

CONSONANTS = %w[
b
c
d
f
g
h
j
k
l
m
n
p
q
r
s
t
v
w
x
z
ç
ð
ħ
ŋ
ɕ
ɖ
ɟ
ɡ
ɢ
ɣ
ɦ
ɫ
ɬ
ɭ
ɮ
ɰ
ɱ
ɲ
ɳ
ɴ
ɸ
ɹ
ɺ
ɻ
ɽ
ɾ
ʀ
ʁ
ʂ
ʃ
ʈ
ʋ
ʎ
ʐ
ʑ
ʒ
ʔ
ʕ
ʙ
ʜ
ʝ
ʟ
ʡ
ʢ
β
θ
χ
ⱱ
]

