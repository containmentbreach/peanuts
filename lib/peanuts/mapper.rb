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

    def ancestor_root
      root
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
      raise "mapping already defined for #{mapping.footprint}" if @footprints[mapping.footprint]
      @mappings << (@footprints[mapping.footprint] = mapping)
    end

    def parse(nut, events)
      for e in events
        m = @footprints.fetch(e.footprint, nil)
        m.from_xml(nut, e) if m
      end
      nut
    end

    def build(nut, writer)
      @root.to_xml(writer) do
        for m in @mappings
          m.to_xml(nut, writer)
        end
      end
    end

    def clear(nut)
      @mappings.each {|m| m.clear(nut) }
    end
  end
end
