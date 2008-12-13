module XmlNuts
  module Converters
    def self.lookup(type)
      lookup!(type)
    rescue ArgumentError
      # swallow
    end

    def self.lookup!(type)
      const_get("Convert_#{type}")
    rescue NameError
      raise ArgumentError, "converter not found for #{type}"
    end

    module Convert_string #:nodoc:
      def self.to_xml(string, options)
        string
      end

      def self.from_xml(string, options = {})
        return nil unless string
        string = case options[:whitespace]
        when nil, :trim, nil then string.strip
        when :preserve then string
        when :collapse then string.gsub(/\s+/, ' ').strip
        end
      end
    end

    module Convert_boolean #:nodoc:
      def self.to_xml(flag, options)
        return nil if flag.nil?
        flag = !!flag
        case options[:format]
        when nil, :truefalse then flag ? 'true' : 'false'
        when :yesno then flag ? 'yes' : 'no'
        when :numeric then flag ? '0' : '1'
        else
          raise ArgumentError, "unrecognized format #{options[:format]}"
        end
      end

      def self.from_xml(string, options)
        return nil unless string
        case string = Convert_string.from_xml(string, options)
        when '1', 'true', 'yes' then true
        when '0', 'false', 'no' then false
        else
          raise ArgumentError, "invalid value for boolean: #{string.inspect}"
        end
      end
    end

    module Convert_integer #:nodoc:
      def self.to_xml(int, options)
        int.to_s
      end

      def self.from_xml(string, options)
        string ? Integer(Convert_string.from_xml(string, options)) : nil
      end
    end

    module Convert_datetime #:nodoc:
      def self.to_xml(time, options)
        time ? time.xmlschema(options[:fraction_digits] || 0) : nil
      end

      def self.from_xml(string, options)
        string ? Time.parse(Convert_string.from_xml(string, options)) : nil
      end
    end
  end
end
