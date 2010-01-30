require 'peanuts/mappable'

module Peanuts #:nodoc:
  # Deprecated. Include Peanuts::MappableObject instead.
  def self.included(other)
    other.send(:include, MappableObject) if ![Object, Kernel].include?(other)
  end

  def self.macro(&block)
    MappableType.macro(&block)
  end
end
