require 'enumerator'
require 'peanuts/source'

module Peanuts
  module XML
    autoload :LibXMLReader, 'peanuts/xml/libxml'

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

      def find_element
        read until node_type == :element
        self
      end

      def self.from(source_type, source)
        new(Source.new(source_type, source))
      end

      def self.method_missing(method, *args, &block)
        return from($1, *args, &block) if method.to_s =~ /^from_(.*)/
        super
      end

      def footprint
        @footprint ||= Footprint.new(self)
      end

      class Footprint
        extend Forwardable
        include Peanuts::XML::Footprint

        def initialize(reader)
          @reader = reader
        end

        def_delegator :@reader, :node_type
        def_delegator :@reader, :local_name, :name
        def_delegator :@reader, :namespace_uri, :ns
      end
    end
  end
end
