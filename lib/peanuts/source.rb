module Peanuts
  class Source
    attr_reader :type, :source

    def initialize(type, source)
      @type, @source = type, source
    end
  end
end
