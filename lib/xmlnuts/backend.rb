require 'monitor'

module XmlNuts
  module XmlBackend
    extend MonitorMixin

    autoload :REXMLBackend, 'xmlnuts/rexml'

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
      Thread.current[:xmlnuts_xml_backend] || default
    end

    def self.current=(backend)
      Thread.current[:xmlnuts_xml_backend] = backend
    end

    private
    def backend #:doc:
      XmlBackend.current
    end
  end
end
