require 'peanuts/mappable'

module Peanuts #:nodoc:
  def self.included(other)
    other.send(:include, MappableObject)
  end

  def self.macro(&block)
    MappableType.macro(&block)
  end
end
