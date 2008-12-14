module XmlNuts
  module Converters
    def self.lookup(type)
      lookup!(type)
    rescue ArgumentError
      nil
    end

    def self.lookup!(type)
      const_get("Convert_#{type}")
    rescue NameError
      raise ArgumentError, "converter not found for #{type}"
    end

    def self.create(type, options)
      create!(type, options)
    rescue ArgumentError
      nil
    end

    def self.create!(type, options)
      lookup!(type).new(options)
    end

    class Convert_nested #:nodoc:
      def initialize(options)
        @type = options[:object_type]
      end

      def to_xml(nut)
        nut
      end

      def from_xml(node)
        node
      end
    end

    class Convert_string #:nodoc:
      def initialize(options)
        @whitespace = options[:whitespace] || :trim
      end

      def to_xml(string)
        string
      end

      def from_xml(string)
        return nil unless string
        string = case @whitespace
        when :trim then string.strip
        when :preserve then string
        when :collapse then string.gsub(/\s+/, ' ').strip
        end
      end
    end

    class Convert_boolean < Convert_string #:nodoc:
      def initialize(options)
        super
        @format = options[:format] || :truefalse
        raise ArgumentError, "unrecognized format #{@format}" unless [:truefalse, :yesno, :numeric].include?(@format)
      end

      def to_xml(flag)
        return nil if flag.nil?
        case @format
        when :truefalse then flag ? 'true' : 'false'
        when :yesno then flag ? 'yes' : 'no'
        when :numeric then flag ? '0' : '1'
        end
      end

      def from_xml(string)
        return nil unless string
        case string = super(string)
        when '1', 'true', 'yes' then true
        when '0', 'false', 'no' then false
        else
          raise ArgumentError, "invalid value for boolean: #{string.inspect}"
        end
      end
    end

    class Convert_integer < Convert_string #:nodoc:
      def initialize(options)
        super
      end

      def to_xml(int)
        int.to_s
      end

      def from_xml(string)
        string && Integer(super(string))
      end
    end

    class Convert_datetime < Convert_string #:nodoc:
      def initialize(options)
        super
        @fraction_digits = options[:fraction_digits] || 0
      end

      def to_xml(time)
        time && time.xmlschema(@fraction_digits)
      end

      def self.from_xml(string)
        string && Time.parse(super(string, options))
      end
    end

    class Convert_list #:nodoc:
      def initialize(options)
        @item_type = options[:item_type] || :string
        @item_converter = Converters.create!(@item_type, options)
      end

      def to_xml(array)
        array && array.map {|x| @item_converter.to_xml(x) } * ' '
      end

      def from_xml(string)
        string && string.split.map! {|x| @item_converter.from_xml(x)}
      end
    end
  end
end
