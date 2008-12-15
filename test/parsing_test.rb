#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'shoulda'
require 'lib/xmlnuts'

class Cheezburger
  include XmlNuts::Nut

  attribute :weight, :integer
end

class Cat
  include XmlNuts::Nut

  namespaces :lol => 'urn:lol', :p => 'b'

  root 'kitteh', :xmlns => 'lol'

  element :eats, [:string], :xmlname => :ration, :xmlns => :lol
  element :friend, :string, :whitespace => :collapse, :xmlns => 'c'
  elements :paws, :string, :xmlname => :paw

  attribute :has_tail, :boolean, :xmlname => 'has-tail', :xmlns => 'b'
  attribute :height, :integer

  element :cheezburger, Cheezburger
end

class ParsingTest < Test::Unit::TestCase
  def setup
    @xml_fragment = <<-EOS
        <mypet xmlns='lol' xmlns:aa='urn:lol' xmlns:bb='b' height=' 12 ' bb:has-tail=' yes  '>
          <friend xmlns='c'>
silly
              mouse
          </friend>
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
    @cat = Cat.parse(@xml_fragment)
  end

  context "A cat" do
    should 'be a friend of a silly mouse' do
      assert_equal 'silly mouse', @cat.friend
    end

    should 'eat tigers and lions' do
      assert_equal ['tigers', 'lions'], @cat.eats
    end

    should 'be 12 meters tall' do
      assert_equal 12, @cat.height
    end

    should 'have tail' do
      assert_equal true, @cat.has_tail
    end

    should 'have four paws' do
      assert_not_nil @cat.paws
      assert_equal 4, @cat.paws.length
      assert_equal %w(one two three four), @cat.paws
    end

    should 'has cheezburger' do
      assert_kind_of Cheezburger, @cat.cheezburger
    end
  end

  context 'A cheezburger' do
    setup do
      @burger = @cat.cheezburger
    end

    should 'weigh 2 kg' do
      assert_equal 2, @burger.weight
    end
  end
end
