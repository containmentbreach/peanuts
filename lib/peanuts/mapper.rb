require 'enumerator'

module Peanuts
  class Mapper
    include Enumerable

    attr_reader :root, :namespaces, :ns_context
    attr_accessor :default_ns, :schema

    def initialize(ns_context = nil, default_ns = nil)
      @ns_context, @default_ns = ns_context, default_ns
      @mappings, @footprints = [], {}
      @namespaces = ns_context ? Hash.new {|h, k| ns_context[k] || raise(IndexError) } : {}
    end

    def root=(root)
      raise 'root already defined' if @root
      # TODO raise 'root in nested scopes not supported' if nested?
      @default_ns = root.namespace_uri unless root.prefix
      @root = root
    end

    def each(&block)
      @mappings.each(&block)
    end

    def <<(mapping)
      fp = Footprint.new(mapping)
      raise "mapping already defined for #{fp}" if @footprints.include?(fp)
      @mappings << (@footprints[fp] = mapping)
    end

    def define_accessors(type)
      each {|m| m.define_accessors(type) }
    end

    def read(nut, reader)
      rdfp = Footprint.new(reader)
      reader.each do
        m = @footprints[rdfp]
        m.read(nut, reader) if m
      end
      nut
    end

    def write(nut, writer)
      @root.write(writer) do |w|
        w.write_namespaces('' => default_ns) if default_ns
        w.write_namespaces(namespaces)
        write_children(nut, w)
      end
      nil
    end

    def write_children(nut, writer)
      each {|m| m.write(nut, writer) } if nut
      nil
    end

    def clear(nut)
      each {|m| m.clear(nut) }
    end

    private
    class Footprint #:nodoc:
      extend Forwardable

      def_delegators :@obj, :node_type, :local_name, :namespace_uri

      def initialize(obj)
        @obj = obj
      end

      def ==(other)
        self.equal?(other) || other &&
          node_type == other.node_type &&
          local_name == other.local_name &&
          namespace_uri == other.namespace_uri
      end

      alias eql? ==

      def hash
        node_type.hash ^ local_name.hash ^ namespace_uri.hash
      end

      def to_s
        "#{node_type}(#{local_name}, #{namespace_uri})"
      end
    end
  end
end
