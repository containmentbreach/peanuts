#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'bigdecimal'
require 'test/unit'
require 'shoulda'
require 'lib/xmlnuts'


class Cheezburger
  include XmlNuts::Nut

  attribute :weight, :float
  attribute :price, :decimal
end

class Cat
  include XmlNuts::Nut

  namespaces :lol => 'urn:x-lol', :kthnx => 'urn:x-lol:kthnx'

  root 'kitteh', :xmlns => :lol

  attribute :has_tail, :boolean, :xmlname => 'has-tail', :xmlns => 'urn:x-lol:kthnx'
  attribute :ears, :integer

  element :ration, [:string], :xmlname => :eats, :xmlns => :kthnx
  element :name, :string, :xmlns => 'urn:x-lol:kthnx'
  elements :paws, :string, :xmlname => :paw

  element :friends, :xmlname => :pals do
    elements :names, :string, :xmlname => :pal
  end

  element :cheezburger, Cheezburger
  element :moar_cheezburgers do
    elements :cheezburger, Cheezburger
  end
end

class ParsingTest < Test::Unit::TestCase
  def setup
    @xml_fragment = <<-EOS
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
          <moar_cheezburgers>
            <cheezburger price='19' weight='685.940' />
            <cheezburger price='7.40' weight='9356.7' />
          </moar_cheezburgers>
        </kitteh>
    EOS
    @cat = Cat.parse(@xml_fragment)
  end

  context "A cat" do
    should 'be named Silly Tom' do
      assert_equal 'Silly Tom', @cat.name
    end

    should 'eat tigers and lions' do
      assert_equal %w(tigers lions), @cat.ration
    end

    should 'be a friend of Chrissy, Missy & Sissy' do
      assert_equal ['Chrissy', 'Missy', 'Sissy'], @cat.friends.names
    end

    should 'have 2 ears' do
      assert_equal 2, @cat.ears
    end

    should 'have a tail' do
      assert @cat.has_tail
    end

    should 'have four paws' do
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

    should 'weigh 14.5547 pounds' do
      assert_equal 14.5547, @burger.weight
    end

    should 'cost $2.05' do
      assert_equal BigDecimal('2.05'), @burger.price
    end
  end
end
