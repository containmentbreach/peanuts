$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'bigdecimal'
require 'test/unit'
require 'rubygems'
require 'shoulda'
require 'peanuts'


class Cheezburger
  include Peanuts

  attribute :weight, :float
  attribute :price, :decimal

  def initialize(weight = nil, price = nil)
    @weight, @price = weight, price
  end

  def eql?(other)
    other && weight == other.weight && price == other.price
  end

  alias == eql?
end

class Paws
  include Peanuts

  elements :paws, :name => :paw, :ns => 'urn:x-lol'
end

class Cat
  include Peanuts

  namespaces :lol => 'urn:x-lol', :kthnx => 'urn:x-lol:kthnx'

  root 'kitteh', :ns => 'urn:x-lol'

  attribute :has_tail?, :boolean, :name => 'has-tail', :ns => :kthnx
  attribute :ears, :integer

  element :ration, [:string], :name => :eats, :ns => :kthnx
  element :name, :ns => 'urn:x-lol:kthnx'
  
  shallow :paws, Paws

  shallow :pals, :ns => :kthnx do
    elements :friends, :name => :pal
  end

  element :cheezburger, Cheezburger
  element :moar_cheezburgers do
    elements :cheezburger, Cheezburger
  end
end

shared_examples_for 'my cat' do
  it 'should be named Silly Tom' do
    @cat.name.should == 'Silly Tom'
  end

  it 'should eat tigers and lions' do
    @cat.ration.should == %w(tigers lions)
  end

  it 'should be a friend of Chrissy, Missy & Sissy' do
    @cat.friends.should == ['Chrissy', 'Missy', 'Sissy']
  end

  it 'should have 2 ears' do
    @cat.ears.should == 2
  end

  it 'should have a tail' do
    @cat.should have_tail
  end

  it 'should have four paws' do
    @cat.paws.should == %w(one two three four)
  end

  it 'should has cheezburger' do
    @cat.cheezburger.should be_kind_of Cheezburger
  end

  it 'should has 2 moar good cheezburgerz' do
    @cat.moar_cheezburgers.cheezburger.should == [
      Cheezburger.new(685.940, BigDecimal('19')),
      Cheezburger.new(9356.7, BigDecimal('7.40'))]
  end
end

shared_examples_for 'my cheezburger' do
  it 'should weigh 14.5547 pounds' do
    @cheezburger.weight.should == 14.5547
  end

  it 'should cost $2.05' do
    @cheezburger.price.should == BigDecimal('2.05')
  end
end

shared_examples_for 'sample kitteh' do
  before :all do
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
          <kthnx:pals>
            <pal>Chrissy</pal>
            <pal>Missy</pal>
            <pal>Sissy</pal>
          </kthnx:pals>
          <paws>
            <paw>  one</paw>
            <paw> two </paw>
            <paw>three</paw>
            <paw>four</paw>
          </paws>
          <cheezburger price='2.05' weight='14.5547' />
          <moar_cheezburgers>
            <cheezburger price='19' weight='685.940' />
            <cheezburger price='7.40' weight='9356.7' />
          </moar_cheezburgers>
        </kitteh>
    EOS
    @cat = Cat.from_xml(@xml_fragment)
    @cheezburger = @cat.cheezburger
  end

  it_should_behave_like 'my cat', 'my cheezburger'
end

describe 'My cat' do
  it_should_behave_like 'sample kitteh'
end

describe 'My cat saved and restored' do
  it_should_behave_like 'sample kitteh'

  before :all do
    @cat = Cat.from_xml(@cat.to_xml)
  end
end
