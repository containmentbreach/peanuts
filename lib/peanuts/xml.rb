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
    autoload :LibXML, 'peanuts/xml/libxml'

    def self.default
      @@default ||= LibXML
    end

    def self.schema(schema_type, source)
      default.schema(schema_type, source)
    end

    def self.method_missing(method, *args, &block)
      case method.to_s
      when /^(.*)_schema_from_(.*)$/
        XML.schema($1.to_sym, args.first)
      else
        super
      end
    end

    class Reader
      include Enumerable

      def self.new(*args, &block)
        cls = self == Reader ? XML.default::Reader : self
        obj = cls.allocate
        obj.send(:initialize, *args, &block)
        obj
      end
    end

    class Writer
      def self.new(*args, &block)
        cls = self == Writer ? XML.default::Writer : self
        obj = cls.allocate
        obj.send(:initialize, *args, &block)
        obj
      end
    end
  end
end
