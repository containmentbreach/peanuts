#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'shoulda'
require 'lib/xmlnuts'

class Cheezburger
  include XmlNuts::Nut

  attribute :weight, :integer
end

class Pet
  include XmlNuts::Nut

  namespaces :aa => 'a', :p => 'b'

  element :eats, [:string], :xmlname => :ration, :xmlns => 'a'
  element :species, :string, :whitespace => :collapse, :xmlns => 'c'
  elements :paws, :string, :xmlname => :paw

  attribute :has_tail, :boolean, :xmlname => 'has-tail', :xmlns => 'b'
  attribute :height, :integer

  element :cheezburger, Cheezburger
end

class ParsingTest < Test::Unit::TestCase
  context "Old McDonald's pet" do
    setup do
      @xml_fragment = <<-EOS
        <mypet xmlns:aa='a' xmlns:bb='b' height=' 12 ' bb:has-tail=' yes  '>
          <species xmlns='c'>
silly
              mouse
          </species>
          <aa:ration>
            tigers
            lions
          </aa:ration>
          <paw>  one</paw>
          <paw> two </paw>
          <paw>three</paw>
          <paw>four</paw>
          <cheezburger weight='2'>
          </cheezburger>
          <cub age='4'>
          </cub>
        </mypet>
      EOS
      @pet = Pet.parse(@xml_fragment)
    end

    should 'be a silly mouse' do
      assert_equal 'silly mouse', @pet.species
    end

    should 'eat tigers and lions' do
      assert_equal ['tigers', 'lions'], @pet.eats
    end

    should 'be 12 meters tall' do
      assert_equal 12, @pet.height
    end

    should 'have tail' do
      assert_equal true, @pet.has_tail
    end

    should 'have four paws' do
      assert_not_nil @pet.paws
      assert_equal 4, @pet.paws.length
      assert_equal %w(one two three four), @pet.paws
    end

    context 'should has cheezburger' do
      setup do
        assert_not_nil @burger = @pet.cheezburger
        assert_kind_of Cheezburger, @pet.cheezburger
      end

      context 'that' do
        should 'weigh 2 kg' do
          assert_equal 2, @burger.weight
        end
      end
    end
  end
end
