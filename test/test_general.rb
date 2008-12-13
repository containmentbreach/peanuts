#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'shoulda'
require 'lib/xmlnuts'

class Pet
  include XmlNuts::Nut

  element :eats, :string, :xmlname => :ration
  element :species, :string, :whitespace => :collapse
  attribute :has_tail, :boolean, :xmlname => 'has-tail'
  attribute :height, :integer
end

class GeneralTest < Test::Unit::TestCase
  context 'A correct XML sample' do
    setup do
      @xml_fragment = <<-EOS
        <root height=' 12 ' has-tail=' yes  '>
          <species>   silly
              mouse
          </species>
          <ration>  tigers
          </ration>
        </root>
      EOS
      @pet = Pet.parse(@xml_fragment)
    end

    should 'be parsed according to conversion options and defaults' do
      assert_equal 'tigers', @pet.eats
      assert_equal 'silly mouse', @pet.species
      assert_equal 12, @pet.height
      assert_equal true, @pet.has_tail
    end
  end
end
