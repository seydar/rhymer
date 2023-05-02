require 'sequel'

DB = Sequel.connect "sqlite://ipagem.db"

class Phonetic

  def self.find_all(sanat)
    words = DB[:phonetics].filter(:word => sanat.map(&:upcase)).all
    words.map {|w| w[:phonetic].to_s }
  end

  def self.find(sana)
    word = DB[:phonetics].filter(:word => sana.upcase).first
    word && word[:phonetic].to_s
  end
end

class Array
  def to_ipa
    Phonetic::find_all self
  end
end

class String
  def to_ipa
    Phonetic::find self
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

