require 'xmlnuts/mappings'

module XmlNuts #:nodoc:
  # See also +ClassMethods+
  module Nut
    include XmlBackend

    def self.included(other) #:nodoc:
      other.extend(ClassMethods)
    end

    # See also Nut#build
    module ClassMethods
      include XmlBackend
      include Mappings

      #    namespaces(hash) -> a Hash
      #    namespaces       -> a Hash
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

      #    element(name, [type[, options]]) -> Mappings::Element or Mappings::ElementValue
      #
      # Defines single-element mapping.
      #
      # === Arguments
      # +name+::    Accessor name
      # +type+::    Element type. +:string+ assumed if omitted. (see +Converter+)
      # +options+:: +:xmlname+, +:xmlns+, converter options (see +Converter+)
      #
      # === Example:
      #    class Cat
      #      include XmlNuts::Nut
      #      ...
      #      element :name, :string, :whitespace => :collapse
      #      element :cheeseburger, Cheeseburger, :xmlname => :cheezburger
      #      ...
      #    end
      def element(name, type = :string, options = {})
        define_accessor name
        (mappings << (type.is_a?(Class) ? Element : ElementValue).new(name, type, options)).last
      end

      #    elements(name, [type[, options]]) -> Mappings::Element or Mappings::ElementValue
      #
      # Defines multiple elements mapping.
      #
      # === Arguments
      # +name+::    Accessor name
      # +type+::    Element type. +:string+ assumed if omitted. (see +Converter+)
      # +options+:: +:xmlname+, +:xmlns+, converter options (see +Converter+)
      #
      # === Example:
      #    class RichCat
      #      include XmlNuts::Nut
      #      ...
      #      elements :ration, :string, :whitespace => :collapse
      #      elements :cheeseburgers, Cheeseburger, :xmlname => :cheezburgers
      #      ...
      #    end
      def elements(name, type = :string, options = {})
        define_accessor name
        (mappings << (type.is_a?(Class) ? Elements : ElementValues).new(name, type, options)).last
      end

      #    attribute(name, [type[, options]]) -> Mappings::Attribute or Mappings::AttributeValue
      #
      # Defines attribute mapping.
      #
      # === Arguments
      # +name+::    Accessor name
      # +type+::    Element type. +:string+ assumed if omitted. (see +Converter+)
      # +options+:: +:xmlname+, +:xmlns+, converter options (see +Converter+)
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
        mappings << Attribute.new(name, type, options)
      end

      #    mappings -> Array
      #
      # Returns all previously defined XmlNuts mappings on a class.
      def mappings
        @mappings ||= []
      end

      def parse(source, options = {})
        source = backend.source(source, options)
        raise ArgumentError, 'invalid source' unless source
        parse_node(new, source)
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
      def define_accessor(name)
        raise "#{name}: name is already defined or reserved" if method_defined?(name) || method_defined?("#{name}=")
        attr_accessor name
      end

      def callem(method, *args)
        mappings.each {|m| m.send(method, *args) }
      end
    end

    #    build([options])              -> root element or string
    #    build([options])              -> root element or string
    #    build(destination[, options]) -> destination
    #    
    # Defines attribute mapping.
    #
    # === Arguments
    # +destination+:: Can be given a symbol a backend-specific object,
    #                 an instance of String or IO classes.
    # - +:string+   -> will return an XML string.
    # - +:document+ -> will return a backend specific document object.
    # - +:object+   -> will return a backend specific object. New document will be created.
    # - an instance of +String+:    the contents of the string will be replaced with
    #                the generated XML.
    # - an instance of +IO+: the IO will be written to.
    # +options+::     Backend-specific options.
    #
    # === Example:
    #    cat = Cat.new
    #    cat.name = 'Pussy'
    #    puts cat.build
    #
    #    doc = REXML::Document.new
    #    cat.build(doc)
    #    puts doc.to_s
    def build(destination = :string, options = {})
      bui
      options, destination = destination, :string if destination.is_a?(Hash)
      backend.build(self, destination, options)
    end
  end
end
