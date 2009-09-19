# To change this template, choose Tools | Templates
# and open the template in the editor.

module Peanuts
  class Source
    attr_reader :type, :source

    def initialize(type, source)
      @type, @source = type, source
    end
  end
end
