require 'string_to_ipa'

class StringToIpa::Phonetic
  def self.database
    @@database
  end
#
#  def to_ipa
#    # No idea why this shitty hack is required
#    phonetic = database.execute("SELECT phonetic from phonetics where word = \"#{@word.upcase}\"")
#
#    # Changed for my purposes
#    if phonetic == []
#      return "" #@word
#    else
#      return phonetic[0]["phonetic"]
#    end
#  end
end

CS = ["ˈ", "ɑ", "b", "ɝ", "g", "k", "ə", "n", "ˌ", "ɫ", "i", "s", "ɛ", "θ", "m", "t", "ɔ", "r", "d", "v", "a", "z", "æ", "e", "ɪ", "o", "ʊ", "ŋ", "ʃ", "ʒ", "j", "h", "u", "ʌ", "f", "p", "w", "ð", "O", "R", "C", "E", "_", "A", "M", "I", "N", "S", "�", "J", "H", "D", "'", "U", "V", "G", "T", "L", "Y", "Z", "Q", "K", "F", "P", "X", "(", "1", ")", "W", "B"]

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

