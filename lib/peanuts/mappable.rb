require 'peanuts/xml'
require 'peanuts/mappings'
require 'peanuts/mapper'

module Peanuts #:nodoc:
  # See also +MappableType+
  module MappableObject
    def self.included(other) #:nodoc:
      MappableType.init(other)
    end

    def from_xml(source, options = {})
      source = XML::Reader.new(source, options) unless source.is_a?(XML::Reader)
      e = source.find_element
      e && self.class.mapper.restore(self, source)
    end

    #    save_to(:string|:document[, options])      -> new_string|new_document
    #    save_to(string|iolike|document[, options]) -> string|iolike|document
    #
    # Defines attribute mapping.
    #
    # [+options+] Backend-specific options
    #
    # === Example:
    #    cat = Cat.new
    #    cat.name = 'Pussy'
    #    puts cat.save_to(:string)
    #    ...
    #    doc = LibXML::XML::Document.new
    #    cat.save_to(doc)
    #    puts doc.to_s
    def to_xml(dest = :string, options = {})
      dest = XML::Writer.new(dest, options) unless dest.is_a?(XML::Writer)
      self.class.mapper.save(self, dest)
      dest.result
    end
  end

  # See also +MappableObject+.
  module MappableType
    include Mappings

    def self.init(cls, ns_context = nil, default_ns = nil, &block) #:nodoc:
      cls.instance_eval do
        extend MappableType
        @mapper = Mapper.new(ns_context, default_ns)
        instance_eval(&block) if block_given?
      end
      cls
    end

    #    mapper -> Mapper
    #
    # Returns the mapper for the class.
    attr_reader :mapper

    #    namespaces(hash) -> Hash
    #    namespaces       -> Hash
    #
    # Updates and returns class-level prefix mappings.
    # When given a hash of mappings merges it over current.
    # When called withot arguments simply returns current mappings.
    #
    # === Example:
    #    class Cat
    #      include Peanuts
    #      namespaces :lol => 'urn:lol', ...
    #      ...
    #    end
    def namespaces(map = nil)
      map ? mapper.namespaces.update(map) : mapper.namespaces
    end

    #    root(local_name[, :ns => ...]) -> Mappings::Root
    #    root                           -> Mappings::Root
    #
    # Defines element name.
    # TODO: moar details
    #
    # [+local_name+] Element name
    # [+options+] <tt>:ns => 'uri'|:prefix</tt> Element namespace
    #
    # === Example:
    #    class Cat
    #      include Peanuts
    #      ...
    #      root :kitteh, :ns => 'urn:lol'
    #      ...
    #    end
    def root(local_name = nil, options = {})
      mapper.root = Root.new(local_name, prepare_options(:root, options)) if local_name
      mapper.root
    end

    #    element(name[, type][, options])   -> mapping_object
    #    element(name[, options]) { block }  -> mapping_object
    #
    # Defines single-element mapping.
    #
    # [+name+]    Accessor name
    # [+type+]    Element type. <tt>:string</tt> assumed if omitted (see +Converter+).
    # [+options+] <tt>name</tt>, <tt>:ns</tt>, converter options (see +Converter+).
    # [+block+]   An anonymous class definition.
    #
    # === Example:
    #    class Cat
    #      include Peanuts
    #      ...
    #      element :name, :whitespace => :collapse
    #      element :ears, :integer
    #      element :cheeseburger, Cheeseburger, :name => :cheezburger
    #      ...
    #    end
    def element(name, *args, &block)
      add_mapping(:element, name, *args, &block)
    end

    #    shallow_element(name, type[, options])     -> mapping_object
    #    shallow_element(name[, options]) { block }  -> mapping_object
    #
    # Defines single-element shallow mapping.
    #
    # [+name+]    Accessor name
    # [+type+]    Element type. Either this or _block_ is required.
    # [+options+] <tt>:name</tt>, <tt>:ns</tt>, converter options (see +Converter+).
    # [+block+]   An anonymous class definition.
    #
    # === Example:
    #    class Cat
    #      include Peanuts
    #      ...
    #      shallow :friends do
    #        element :friends, :name => :friend
    #      end
    #      shallow :cheeseburger, Cheeseburger, :name => :cheezburger
    #      ...
    #    end
    def shallow_element(name, *args, &block)
      add_mapping(:shallow_element, name, *args, &block)
    end

    alias shallow shallow_element

    #    elements(name[, type][, options])   -> mapping_object
    #    elements(name[, options]) { block }  -> mapping_object
    #
    # Defines multiple elements mapping.
    #
    # [+name+]    Accessor name
    # [+type+]    Element type. <tt>:string</tt> assumed if omitted (see +Converter+).
    # [+options+] <tt>name</tt>, <tt>:ns</tt>, converter options (see +Converter+).
    # [+block+]   An anonymous class definition.
    #
    # === Example:
    #    class RichCat
    #      include Peanuts
    #      ...
    #      elements :ration, :string, :whitespace => :collapse
    #      elements :cheeseburgers, Cheeseburger, :name => :cheezburger
    #      ...
    #    end
    def elements(name, *args, &block)
      add_mapping(:elements, name, *args, &block)
    end

    #    attribute(name[, type][, options]) -> mapping_object
    #
    # Defines attribute mapping.
    #
    # [+name+]    Accessor name
    # [+type+]    Element type. <tt>:string</tt> assumed if omitted (see +Converter+).
    # [+options+] <tt>name</tt>, <tt>:ns</tt>, converter options (see +Converter+).
    #
    # === Example:
    #    class Cat
    #      include Peanuts
    #      ...
    #      element :name, :string, :whitespace => :collapse
    #      element :cheeseburger, Cheeseburger, :name => :cheezburger
    #      ...
    #    end
    def attribute(name, *args)
      add_mapping(:attribute, name, *args)
    end

    def schema(schema = nil)
      mapper.schema = schema if schema
      mapper.schema
    end

    def from_xml(source, options = {})
      new.from_xml(source, options)
    end

    private
    def object_type?(type)
      type.is_a?(Class) && !(type < Converter)
    end

    def add_mapping(node, name, *args, &block)
      type, options = *args
      type, options = (block ? Class.new : :string), type if type.nil? || type.is_a?(Hash)

      object_type = object_type?(type)
      options = prepare_options(node, options || {})

      mapper << m = case node
      when :element
        options.delete(:shallow) ? ShallowElement : (object_type ? Element : ElementValue)
      when :elements
        object_type ? Elements : ElementValues
      when :attribute
        Attribute
      when :shallow_element
        ShallowElement
      end.new(name, type, options)

      raise ArgumentError, 'bad type for shallow element' if !object_type && m.is_a?(ShallowElement)

      default_ns = m.prefix ? mapper.default_ns : m.namespace_uri
      if object_type && !type.is_a?(MappableType)
        raise ArgumentError, 'block is required' unless block
        MappableType.init(type, mapper.namespaces, default_ns, &block)
      end
      m.define_accessors(self)
      m
    end

    def prepare_options(node, options)
      ns = options.fetch(:ns) {|k| node == :attribute ? nil : options[k] = mapper.default_ns }
      if ns.is_a?(Symbol)
        raise ArgumentError, "undefined prefix: #{ns}" unless options[:ns] = mapper.namespaces[ns]
        options[:prefix] = ns
      end
      options
    end
  end
end
