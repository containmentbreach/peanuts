require 'xmlnuts/nuts'

#class Cheezburger
#  include XmlNuts::Nut
#
#  attribute :weight, :integer
#end
#
#class Pet
#  include XmlNuts::Nut
#
#  namespaces :pipi => 'a', :piz => 'b'
#
#  element :eats, [:string], :xmlname => :ration, :xmlns => 'a'
#  element :species, :string, :whitespace => :collapse
#  elements :paws, :string, :xmlname => :paw
#
#  attribute :has_tail, :boolean, :xmlname => 'has-tail', :xmlns => 'b'
#  attribute :height, :integer
#
#  element :cheezburger, Cheezburger
#end
#
#xml_fragment = <<-EOS
#        <mypet xmlns:pizda="b" height=' 12 ' pizda:has-tail=' yes  '>
#          <species>
#silly
#              mouse
#          </species>
#          <pi:ration xmlns:pi="a">
#            tigers
#            lions
#          </pi:ration>
#          <paw>  one</paw>
#          <paw> two </paw>
#          <paw>three</paw>
#          <paw>four</paw>
#          <cheezburger weight='2'>
#          </cheezburger>
#          <cub age='4'>
#          </cub>
#        </mypet>
#EOS
#pet = Pet.parse(xml_fragment)
#
#puts Pet.build(pet)
