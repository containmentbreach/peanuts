require 'peanuts/mappable'

module Peanuts #:nodoc:
  def self.included(other)
    other.send(:include, MappableObject)
  end
end
