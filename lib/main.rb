require 'xmlnuts'

class Anus
  include XmlNuts::Nut

  element :len, Integer
  element :fuck, Time
  attribute :anus
end

class Penis
  include XmlNuts::Nut

  element :len, Integer
  element :fuck, Time
  attribute :anal_d, String, :xmlname => 'anal-d'

  has_one :anus, Anus
end

penis = Penis.new
penis.len = nil
penis.fuck = Time.now
penis.anal_d = 'big'
penis.anus = Anus.new
penis.anus.len = 40

puts Penis.build(penis).to_s

xml = '<root anal-d="pii"><len></len><fuck>2008-12-12T15:18:39+02:00</fuck></root>'

penis = Penis.parse(xml)
puts Penis.build(penis).to_s