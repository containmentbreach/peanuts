require 'enumerator'

module Peanuts
  class Mapper
    include Enumerable

    attr_reader :root, :namespaces, :nscontext, :container
    attr_accessor :schema

    def initialize
      @mappings, @footprints = [], {}
      @namespaces = Hash.new do |h, k|
        nscontext && nscontext[k] || raise(IndexError)
      end
    end

    def root=(root)
      raise 'root already defined' if @root
      raise 'root in nested scopes not supported' if nested?
      @root = root
    end

    def set_context(container, nscontext)
      @container, @nscontext = container, nscontext
    end

    def nested?
      !!container
    end

    def each(&block)
      @mappings.each(&block)
    end

    def <<(mapping)
      fp = MappingFootprint.new(mapping)
      raise "mapping already defined for #{fp}" if @footprints.include?(fp)
      @mappings << (@footprints[fp] = mapping)
    end

    def parse(nut, reader)
      rdfp = ReaderFootprint.new(reader)
      reader.each do
        m = @footprints[rdfp]
        m.from_xml(nut, reader) if m
      end
      nut
    end

    def build(nut, writer)
      if @root
        @root.to_xml(writer) do
          _save(nut, writer)
        end
      else
        _save(nut, writer)
      end
      writer.result
    end

    def clear(nut)
      @mappings.each {|m| m.clear(nut) }
    end

    private
    def _save(nut, writer)
      @mappings.each {|m| m.to_xml(nut, writer) }
    end

    class Footprint
      def ==(other)
        self.equal?(other) || other && node_type == other.node_type && name == other.name && ns == other.ns
      end

      alias eql? ==

      def hash
        node_type.hash ^ name.hash ^ ns.hash
      end

      def to_s
        "#{node_type}(#{name}, #{ns})"
      end
    end

    class MappingFootprint < Footprint
      extend Forwardable

      def initialize(mapping)
        @mapping = mapping
      end

      def_delegator :@mapping, :node_type
      def_delegator :@mapping, :xmlname, :name
      def_delegator :@mapping, :xmlns, :ns
    end

    class ReaderFootprint < Footprint
      extend Forwardable

      def initialize(reader)
        @reader = reader
      end

      def_delegator :@reader, :node_type
      def_delegator :@reader, :local_name, :name
      def_delegator :@reader, :namespace_uri, :ns
    end
  end
end
