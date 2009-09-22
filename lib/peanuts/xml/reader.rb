require 'enumerator'

class Hash
  def from_namespace(ns)
    rx = /^#{Regexp.quote(ns.to_s)}_(.*)$/
    inject({}) do |a, p|
      a[$1.to_sym] = p[1] if p[0].to_s =~ rx
      a
    end
  end

  def from_namespace!(ns)
    h = from_namespace(ns)
    h.each_key {|k| delete(:"#{ns}_#{k}") }
    h
  end
end

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

      def initialize(options = {})

      end

      def self.method_missing(method, *args, &block)
        case method.to_s
        when /^from_(.*)$/
          new($1.to_sym, *args, &block)
        when /^(.*)_schema_from_(.*)$/
          schema($2.to_sym, args[0], $1.to_sym)
        else
          super
        end
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
