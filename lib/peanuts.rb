require 'peanuts/xml'
require 'peanuts/mappings'
require 'peanuts/mapper'

module Peanuts #:nodoc:
  def self.included(other) #:nodoc:
    other.send(:include, MappableObject)
  end

  # See also +MappableType+
  module MappableObject
    def self.included(other) #:nodoc:
      init(other)
    end

    def self.init(cls, ns_context = nil, default_ns = nil, &block) #:nodoc:
      cls.instance_eval do
        extend MappableType
        @mapper = Mapper.new(ns_context, default_ns)
        instance_eval(&block) if block_given?
      end
    end

    def restore(reader)
      self.class.restore(reader, self)
    end

    def restore_from(reader)
      self.class.restore_from(reader, self)
    end

    def save(writer)
      self.class.save(self, writer)
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
    #    puts cat.save_to(:string)
    #    ...
    #    doc = LibXML::XML::Document.new
    #    cat.save_to(doc)
    #    puts doc.to_s
    def save_to(*args)
      self.class._source_or_dest(*args) do |dest_type, dest, options|
        save(XML::Writer.new(dest, dest_type, options))
      end
    end
  end
  
  # See also +MappableObject+.
  module MappableType
    include Mappings

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
    #      include Peanuts
    #      ...
    #      root :kitteh, :xmlns => 'urn:lol'
    #      ...
    #    end
    def root(xmlname = nil, options = {})
      mapper.root = Root.new(xmlname, prepare_options(:root, options)) if xmlname
      mapper.root
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
    #      include Peanuts
    #      ...
    #      element :name, :string, :whitespace => :collapse
    #      element :cheeseburger, Cheeseburger, :xmlname => :cheezburger
    #      ...
    #    end
    def element(name, *args, &block)
      add_mapping(:element, name, *args, &block)
    end

    def shallow_element(name, *args, &block)
      add_mapping(:shallow_element, name, *args, &block)
    end

    alias shallow shallow_element

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
    #      include Peanuts
    #      ...
    #      elements :ration, :string, :whitespace => :collapse
    #      elements :cheeseburgers, Cheeseburger, :xmlname => :cheezburger
    #      ...
    #    end
    def elements(name, *args, &block)
      add_mapping(:elements, name, *args, &block)
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
    #      include Peanuts
    #      ...
    #      element :name, :string, :whitespace => :collapse
    #      element :cheeseburger, Cheeseburger, :xmlname => :cheezburger
    #      ...
    #    end
    def attribute(name, *args)
      add_mapping(:attribute, name, *args)
    end

    def schema(schema = nil)
      mapper.schema = schema if schema
      mapper.schema
    end

    def restore(reader)
      e = reader.find_element
      e && _restore(e)
    end

    def restore_from(*args)
      _source_or_dest(*args) do |source_type, source, options|
        restore(XML::Reader.new(source, source_type, options))
      end
    end

    def save(nut, writer)
      _save(nut, writer)
      writer.result
    end

    def _source_or_dest(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      type, source = *args
      type, source = :string, type unless type.is_a?(Symbol)
      yield type, source, options
    end

    private
    def _restore(reader, nut = new)
      mapper.restore(nut, reader)
      nut
    end

    def _save(nut, writer)
      mapper.save(nut, writer)
    end

    def add_mapping(node, name, *args, &block)
      type, options = *args
      type, options = (block ? Class.new : :string), type if type.nil? || type.is_a?(Hash)

      options = prepare_options(node, options || {})

      mapper << m = case node
      when :element
        (shallow = options.delete(:shallow)) ? ShallowElement : (type.is_a?(Class) ? Element : ElementValue)
      when :elements
        type.is_a?(Class) ? Elements : ElementValues
      when :attribute
        Attribute
      when :shallow_element
        node, shallow = :element, true
        ShallowElement
      end.new(name, type, options)

      if shallow
        if type.is_a?(MappableType)
          type.mapper.each {|m| m.define_accessor(self) }
        else
          raise ArgumentError, 'block is required' unless block
          ShallowObject.init(type, self, mapper.namespaces, m.xmlns, &block)
        end
      else
        if type.is_a?(Class) && !type.is_a?(MappableType)
          raise ArgumentError, 'block is required' unless block
          MappableObject.init(type, mapper.namespaces, m.xmlns, &block)
        end
        define_accessor(m)
      end
      m
    end

    def prepare_options(node, options)
      ns = options.fetch(:xmlns) {|k| node == :attribute ? nil : options[k] = root && root.xmlns || mapper.default_ns }
      if ns.is_a?(Symbol)
        raise ArgumentError, "undefined prefix: #{ns}" unless options[:xmlns] = mapper.namespaces[ns]
        options[:prefix] = ns
      end
      options
    end

    def define_accessor(mapping)
      mapping.define_accessor(self)
    end
  end

  class ShallowObject #:nodoc:
    def self.included(other)
      init(other)
    end

    def self.init(cls, owner, ns_context = nil, default_ns = nil, &block)
      MappableObject.init(cls, ns_context, default_ns) do
        @owner = owner
        extend ShallowType
        instance_eval(&block) if block_given?
      end
    end
  end

  module ShallowType #:nodoc:
    def define_accessor(mapping)
      mapping.define_accessor(@owner)
    end
  end
end
