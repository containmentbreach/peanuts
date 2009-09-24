require 'enumerator'

module Peanuts
  class Mapper
    include Enumerable

    attr_reader :root, :namespaces, :ns_context, :default_ns
    attr_accessor :schema

    def initialize(ns_context = nil, default_ns = nil)
      @ns_context, @default_ns = ns_context, default_ns
      @mappings, @footprints = [], {}
      @namespaces = ns_context ? Hash.new {|h, k| ns_context[k] || raise(IndexError) } : {}
    end

    def root=(root)
      raise 'root already defined' if @root
      # TODO raise 'root in nested scopes not supported' if nested?
      @root = root
    end

    def each(&block)
      @mappings.each(&block)
    end

    def <<(mapping)
      fp = MappingFootprint.new(mapping)
      raise "mapping already defined for #{fp}" if @footprints.include?(fp)
      @mappings << (@footprints[fp] = mapping)
    end

    def restore(nut, reader)
      rdfp = ReaderFootprint.new(reader)
      reader.each do
        m = @footprints[rdfp]
        m.restore(nut, reader) if m
      end
      nut
    end

    def save(nut, writer)
      @root ? @root.save(writer) { _save(nut, writer) } : _save(nut, writer)
    end

    def clear(nut)
      @mappings.each {|m| m.clear(nut) }
    end

    private
    def _save(nut, writer)
      @mappings.each {|m| m.save(nut, writer) } if nut
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
