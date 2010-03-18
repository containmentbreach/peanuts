# encoding: UTF-8

module Peanuts
  autoload :Time, 'time'
  autoload :BigDecimal, 'bigdecimal'

  # === Currently supported types:
  # string::      see +Convert_string+
  # boolean::     see +Convert_boolean+, +Convert_yesno+
  # numeric::     see +Convert_integer+, +Convert_decimal+, +Convert_float+
  # date & time:: see +Convert_datetime+
  # lists::       see +Convert_list+
  class Converter
    def self.lookup(type)
      lookup!(type)
    rescue ArgumentError
      nil
    end

    def self.lookup!(type)
      begin
        const_get("Convert_#{type}")
      rescue NameError
        raise ArgumentError, "converter not found for #{type}"
      end
    end

    def self.create(type, options)
      create!(type, options)
    rescue ArgumentError
      nil
    end

    def self.create!(type, options)
      case type
      when Symbol
        lookup!(type)
      else
        type
      end.new(options)
    end

    # Who could have thought... a string.
    #
    # Specifier:: <tt>:string</tt>
    #
    # ==== Options:
    # [<tt>:whitespace => :collapse</tt>]
    #   Whitespace handling behavior.
    #   [<tt>:trim</tt>] Trim whitespace from both ends.
    #   [<tt>:collapse</tt>] Collapse consecutive whitespace + trim as well.
    #   [<tt>:preserve</tt>] Keep'em all.
    class Convert_string < Converter
      def initialize(options)
        @whitespace = options[:whitespace] || :collapse
      end

      def to_xml(string)
        string
      end

      def from_xml(string)
        return nil unless string
        string = case @whitespace
        when :trim then string.gsub(/\A\s*|\s*\Z/, '')
        when :preserve then string
        when :collapse then string.gsub(/\s+/, ' ').gsub(/\A\s*|\s*\Z|\s*(?=\s)/, '')
        end
      end
    end

    # An XSD boolean.
    #
    # Specifier:: <tt>:boolean</tt>
    #
    # ==== Options:
    # [<tt>:format => :true_false</tt>]
    #   Format variation.
    #   [<tt>:true_false</tt>] <tt>true/false</tt>
    #   [<tt>:yes_no</tt>] <tt>yes/no</tt>
    #   [<tt>:numeric</tt>] <tt>0/1</tt>
    #   In addition supports all options of +Convert_string+.
    #
    # See also +Convert_yesno+.
    class Convert_boolean < Convert_string
      def initialize(options)
        super
        @format = options[:format] || :truefalse
        raise ArgumentError, "unrecognized format #{@format}" unless [:truefalse, :yesno, :numeric].include?(@format)
      end

      def to_xml(flag)
        return nil if flag.nil?
        string = case @format
        when :true_false, :truefalse then flag ? 'true' : 'false'
        when :yes_no, :yesno then flag ? 'yes' : 'no'
        when :numeric then flag ? '0' : '1'
        end
        super(string)
      end

      def from_xml(string)
        case string = super(string)
        when nil then nil
        when '1', 'true', 'yes' then true
        when '0', 'false', 'no' then false
        else
          raise ArgumentError, "invalid value for boolean: #{string.inspect}"
        end
      end
    end

    # The same as +Convert_boolean+ but with the <tt>:yes_no</tt> default format.
    #
    # Specifier:: <tt>:yesno</tt>
    class Convert_yesno < Convert_boolean
      def initialize(options)
        options[:format] ||= :yes_no
        super
      end
    end

    # An integer.
    #
    # Specifier:: <tt>:integer</tt>
    #
    # ==== Options
    # Accepts all options of +Convert_string+.
    class Convert_integer < Convert_string
      def initialize(options)
        super
      end

      def to_xml(int)
        super(int.to_s)
      end

      def from_xml(string)
        (string = super(string)) && Integer(string)
      end
    end

    # A decimal.
    #
    # Specifier:: <tt>:decimal</tt>
    # Ruby type:: +BigDecimal+
    #
    # ==== Options
    # Accepts all options of +Convert_string+.
    class Convert_decimal < Convert_string
      def initialize(options)
        super
      end

      def to_xml(int)
        super(int && int.to_s('F'))
      end

      def from_xml(string)
        (string = super(string)) && BigDecimal.new(string)
      end
    end

    # A float.
    #
    # Specifier:: <tt>:float</tt>
    #
    # ==== Options
    # [<tt>:precision</tt>] Floating point precision.
    #
    # In addition accepts all options of +Convert_string+.
    class Convert_float < Convert_string
      def initialize(options)
        super
        @precision = options[:precision]
        @format = @precision ? "%f.#{@precision}" : '%f'
      end

      def to_xml(int)
        super(int && sprintf(@format, int))
      end

      def from_xml(string)
        (string = super(string)) && string.to_f
      end
    end

    # An XSD datetime.
    #
    # Specifier:: <tt>:datetime</tt>
    # Ruby type:: +Time+
    #
    # ==== Options
    # Accepts all options of +Convert_string+.
    class Convert_datetime < Convert_string
      def initialize(options)
        super
        @fraction_digits = options[:fraction_digits] || 0
      end

      def to_xml(time)
        super(time && time.xmlschema(@fraction_digits))
      end

      def from_xml(string)
        (string = super(string)) && Time.parse(string)
      end
    end

    # An XSD whitespace-separated list.
    #
    # Specifier::             <tt>:list, :item_type => <em>simple type specifier</em></tt>
    # Alternative specifier:: <tt>[<em>simple type specifier</em>]</tt>
    # Ruby type::             +Array+ of <tt><em>simple type</em></tt>
    #
    # ==== Options
    # All options will be passed to the underlying type converter.
    class Convert_list < Converter
      def initialize(options)
        @item_type = options[:item_type] || :string
        @item_converter = Converter.create!(@item_type, options)
      end

      def to_xml(items)
        items && items.map {|x| @item_converter.to_xml(x) } * ' '
      end

      def from_xml(string)
        string && string.split.map! {|x| @item_converter.from_xml(x)}
      end
    end
  end
end
