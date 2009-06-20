require 'monitor'

module Peanuts
  module XmlBackend
    extend MonitorMixin

    autoload :REXMLBackend, 'peanuts/rexml'

    def self.default
      synchronize do
        unless defined? @@default
          @@default = REXMLBackend.new
          def self.default #:nodoc:
            @@default
          end
          @@default
        end
      end
    end

    def self.default=(backend)
      @@default = backend
    end

    def self.current
      Thread.current[XmlBackend.name] || default
    end

    def self.current=(backend)
      Thread.current[XmlBackend.name] = backend
    end

    private
    def backend #:doc:
      XmlBackend.current
    end
  end
end
