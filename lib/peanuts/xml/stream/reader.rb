require 'enumerator'
require 'peanuts/source'

module Peanuts
  module XML
    module Stream
      autoload :LibXMLReader, 'peanuts/xml/stream/libxml'

      class Reader
        include Enumerable

        class << self
          attr_accessor :default
        end

        def self.new(*args, &block)
          cls = self == Reader ? self.default || LibXMLReader : self
          obj = cls.allocate
          obj.send(:initialize, *args, &block)
          obj
        end

        def initialize(source, options = {})
          @source, @schema = source, options[:schema]
        end

        def self.from(source_type, source)
          new(Source.new(source_type, source))
        end

        def self.method_missing(method, *args, &block)
          return from($1, *args, &block) if method.to_s =~ /^from_(.*)/
          super
        end
      end
    end
  end
end