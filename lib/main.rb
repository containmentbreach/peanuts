require 'rubygems'
require 'peanuts'
require 'peanuts/xml/libxml'

xml_fragment = <<-EOS
        <kitteh xmlns='urn:x-lol' xmlns:kthnx='urn:x-lol:kthnx' ears=' 2 ' kthnx:has-tail=' yes  '>
          <name xmlns='urn:x-lol:kthnx'>
              Silly
              Tom
          </name>
          <kthnx:eats>
            tigers
            lions
          </kthnx:eats>
          <pals>
            <pal>Chrissy</pal>
            <pal>Missy</pal>
            <pal>Sissy</pal>
          </pals>
          <paw>  one</paw>
          <paw> two </paw>
          <paw>three</paw>
          <paw>four</paw>
          <cheezburger price='2.05' weight='14.5547' />
          <cheezburger price='22.05' weight='114.5547' />
          <moar_cheezburgers>
            <cheezburger price='19' weight='685.940'>
              <shit>anus</shit>
            </cheezburger>
            <cheezburger price='7.40' weight='9356.7' />
          </moar_cheezburgers>
        </kitteh>
EOS

class Cheezburger
  include Peanuts

  attribute :weight, :float
  attribute :price, :decimal
end

class Cat
  include Peanuts

  namespaces :lol => 'urn:x-lol', :kthnx => 'urn:x-lol:kthnx'

  root 'kitteh', :xmlns => 'urn:x-lol'

  attribute :has_tail, :boolean, :xmlname => 'has-tail', :xmlns => :kthnx
  element :name, :string, :xmlns => :kthnx#'urn:x-lol:kthnx'
  element :ration, [:string], :xmlname => :eats, :xmlns => :kthnx

  element :friends, :xmlname => :pals do
    elements :names, :string, :xmlname => :pal
  end

  element :cheezburger, Cheezburger
  element :moar_cheezburgers do
    elements :cheezburger, Cheezburger
  end
end

cat = Cat.restore_from(:string, xml_fragment)
puts cat.inspect

puts cat.save_to(:string)