require 'enumerator'

module Peanuts
  class Mapper
    def self.of(cls)
      cls.send(:mapper)
    end

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
      fp = MappingFootprint.new(mapping)
      raise "mapping already defined for #{fp}" if @footprints.include?(fp)
      @mappings << (@footprints[fp] = mapping)
    end

    def define_accessors(type)
      each {|m| m.define_accessors(type) }
    end

    def read(nut, reader)
      rdfp = ReaderFootprint.new(reader)
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

      def hash
        node_type.hash ^ local_name.hash ^ namespace_uri.hash
      end

      def to_s
        "#{node_type}(#{local_name}, #{namespace_uri})"
      end
    end

    class MappingFootprint < Footprint #:nodoc:
      def eql?(other)
        self.equal?(other) || other && @obj.matches?(other)
      end
    end

    class ReaderFootprint < Footprint #:nodoc:
      def eql?(mappingfp)
        mappingfp.eql?(@obj)
      end
    end
  end
end
