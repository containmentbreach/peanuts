require 'xmlnuts/mappings'

module XmlNuts #:nodoc:
  # See also +ClassMethods+
  module Nut
    def self.included(other) #:nodoc:
      other.extend(ClassMethods)
    end

    # See also +Nut+.
    module ClassMethods
      include XmlBackend
      include Mappings

      #    namespaces(hash) -> Hash
      #    namespaces       -> Hash
      #
      # Updates and returns class-level prefix mappings.
      # When given a hash of mappings merges it over current.
      # When called withot arguments simply returns current mappings.
      # 
      # === Example:
      #    class Cat
      #      include XmlNuts::Nut
      #      namespaces :lol => 'urn:lol', ...
      #      ...
      #    end
      def namespaces(mappings = nil)
        @namespaces ||= {}
        mappings ? @namespaces.update(mappings) : @namespaces
      end

      #    root(xmlname[, :xmlns => ...]) -> Mappings::Root
      #    root                           -> Mappings::Root
      #
      # Defines element name.
      # TODO: moar details
      #
      # === Arguments
      # [+xmlname+] Element name
      # [+options+] <tt>:xmlns => <tt> Element namespace
      #
      # === Example:
      #    class Cat
      #      include XmlNuts::Nut
      #      ...
      #      root :kitteh, :xmlns => 'urn:lol'
      #      ...
      #    end
      def root(xmlname = nil, options = {})
        @root = Root.new(xmlname, prepare_options(options)) if xmlname
        @root ||= Root.new('root')
      end

      #    element(name, [type[, options]])   -> Mappings::Element or Mappings::ElementValue
      #    element(name[, options]) { block } -> Mappings::Element
      #
      # Defines single-element mapping.
      #
      # === Arguments
      # [+name+]    Accessor name
      # [+type+]    Element type. <tt>:string</tt> assumed if omitted (see +Converter+).
      # [+options+] <tt>:xmlname</tt>, <tt>:xmlns</tt>, converter options (see +Converter+).
      # [+block+]   An anonymous class definition.
      #
      # === Example:
      #    class Cat
      #      include XmlNuts::Nut
      #      ...
      #      element :name, :string, :whitespace => :collapse
      #      element :cheeseburger, Cheeseburger, :xmlname => :cheezburger
      #      ...
      #    end
      def element(name, type = :string, options = {}, &block)
        type, options = prepare_args(type, options, &block)
        define_accessor name
        (mappings << (type.is_a?(Class) ? Element : ElementValue).new(name, type, prepare_options(options))).last
      end

      #    elements(name, [type[, options]])   -> Mappings::Element or Mappings::ElementValue
      #    elements(name[, options]) { block } -> Mappings::Element
      #
      # Defines multiple elements mapping.
      #
      # === Arguments
      # [+name+]    Accessor name
      # [+type+]    Element type. <tt>:string</tt> assumed if omitted (see +Converter+).
      # [+options+] <tt>:xmlname</tt>, <tt>:xmlns</tt>, converter options (see +Converter+).
      # [+block+]   An anonymous class definition.
      #
      # === Example:
      #    class RichCat
      #      include XmlNuts::Nut
      #      ...
      #      elements :ration, :string, :whitespace => :collapse
      #      elements :cheeseburgers, Cheeseburger, :xmlname => :cheezburger
      #      ...
      #    end
      def elements(name, type = :string, options = {}, &block)
        type, options = prepare_args(type, options, &block)
        define_accessor name
        (mappings << (type.is_a?(Class) ? Elements : ElementValues).new(name, type, prepare_options(options))).last
      end

      #    attribute(name, [type[, options]]) -> Mappings::Attribute or Mappings::AttributeValue
      #
      # Defines attribute mapping.
      #
      # === Arguments
      # [+name+]    Accessor name
      # [+type+]    Element type. <tt>:string</tt> assumed if omitted (see +Converter+).
      # [+options+] <tt>:xmlname</tt>, <tt>:xmlns</tt>, converter options (see +Converter+).
      #
      # === Example:
      #    class Cat
      #      include XmlNuts::Nut
      #      ...
      #      element :name, :string, :whitespace => :collapse
      #      element :cheeseburger, Cheeseburger, :xmlname => :cheezburger
      #      ...
      #    end
      def attribute(name, type = :string, options = {})
        define_accessor name
        mappings << Attribute.new(name, type, prepare_options(options))
      end

      #    mappings -> Array
      #
      # Returns all mappings defined on a class.
      def mappings
        @mappings ||= []
      end

      def parse(source, options = {})
        backend.parse(source, options) {|node| parse_node(new, node) }
      end

      def build(nut, result = :string, options = {})
        options, result = result, :string if result.is_a?(Hash)
        options[:xmlname] ||= root.xmlname
        options[:xmlns_prefix] = namespaces.invert[options[:xmlns] ||= root.xmlns]
        backend.build(result, options) {|node| build_node(nut, node) }
      end

      def build_node(nut, node) #:nodoc:
        backend.add_namespaces(node, namespaces)
        callem(:to_xml, nut, node)
        node
      end

      def parse_node(nut, node) #:nodoc:
        callem(:from_xml, nut, node)
        nut
      end

      private
      def prepare_args(type, options, &block)
        if block_given?
          options = type if type.is_a?(Hash)
          type = Class.new
          type.class_eval do
            include XmlNuts::Nut
            class_eval(&block)
          end
        end
        return type, prepare_options(options)
      end

      def prepare_options(options)
        ns = options[:xmlns]
        if ns.is_a?(Symbol)
          raise ArgumentError, "undefined prefix: #{ns}" unless options[:xmlns] = namespaces[ns]
        end
        options
      end

      def define_accessor(name)
        if method_defined?(name) || method_defined?("#{name}=")
          raise ArgumentError, "#{name}: name already defined or reserved"
        end
        attr_accessor name
      end

      def callem(method, *args)
        mappings.each {|m| m.send(method, *args) }
      end
    end

    def parse(source, options = {})
      backend.parse(source, options) {|node| parse_node(node) }
    end

    #    build([options])              -> root element or string
    #    build([options])              -> root element or string
    #    build(destination[, options]) -> destination
    #
    # Defines attribute mapping.
    #
    # === Arguments
    # [+destination+]
    #   Can be given a symbol a backend-specific object, an instance of String or IO classes.
    #   [<tt>:string</tt>]   will return an XML string.
    #   [<tt>:document</tt>] will return a backend specific document object.
    #   [<tt>:object</tt>]   will return a backend specific object. New document will be created.
    #   [an instance of +String+] the contents of the string will be replaced with the generated XML.
    #   [an instance of +IO+]     the IO will be written to.
    # [+options+] Backend-specific options
    #
    # === Example:
    #    cat = Cat.new
    #    cat.name = 'Pussy'
    #    puts cat.build
    #    ...
    #    doc = REXML::Document.new
    #    cat.build(doc)
    #    puts doc.to_s
    def build(result = :string, options = {})
      self.class.build(self, result, options)
    end
  end
end
