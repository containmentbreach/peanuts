require 'peanuts/xml/stream/reader'

module Peanuts
  class Marshaller
    class << self
      attr_accessor :default_instance
    end

    DEFAULT_OPTIONS = {}

    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def restore(type, events)
      type.mappings.parse(type.new, events)
    end

    self.default_instance = new
  end
end
