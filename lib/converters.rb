module XmlNuts
  module Converters
    def self.lookup(type)
      lookup!(type)
    rescue ArgumentError
      # swallow
    end

    def self.lookup!(type)
      const_get("#{type.name}Converter")
    rescue NameError
      raise ArgumentError, "converter not found for #{type}"
    end

    module StringConverter
      def self.to_xml(string, options)
        string
      end

      def self.from_xml(string, options)
        string
      end
    end

    module IntegerConverter
      def self.to_xml(int, options)
        int.to_s
      end

      def self.from_xml(string, options)
        string ? string.to_i : nil
      end
    end

    module TimeConverter
      def self.to_xml(time, options)
        time ? time.xmlschema(options[:fraction_digits] || 0) : nil
      end

      def self.from_xml(string, options)
        string ? Time.parse(string) : nil
      end
    end
  end
end
