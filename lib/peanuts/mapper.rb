require 'enumerator'

module Peanuts
  class Mapper
    include Enumerable

    def initialize
      @mappings, @footprints = [], {}
    end

    def each(&block)
      @mappings.each(&block)
    end

    def <<(mapping)
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
  end
end
