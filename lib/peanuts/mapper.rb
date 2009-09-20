require 'enumerator'

module Peanuts
  class Mapper
    include Enumerable

    attr_reader :root, :namespaces, :nscontext, :container

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

    def parse_event(nut, event)
      m = @footprints.fetch(event.footprint, nil)
      m.from_xml(nut, event) if m
    end

    def parse(nut, events)
      for e in events
        parse_event(nut, e)
      end
      nut
    end

    def clear(nut)
      @mappings.each {|m| m.clear(nut) }
    end
  end
end
