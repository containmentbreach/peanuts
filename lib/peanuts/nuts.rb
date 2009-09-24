require 'peanuts/mappings'
require 'peanuts/mapper'

module Peanuts #:nodoc:
  def self.included(other) #:nodoc:
    init(other)
  end

  def self.init(cls, ns_context = nil, default_ns = nil, &block) #:nodoc:
    cls.instance_eval do
      include InstanceMethods
      extend ClassMethods
      @mapper = Mapper.new(ns_context, default_ns)
      instance_eval(&block) if block_given?
    end
  end

  # See also +InstanceMethods+.
  module ClassMethods
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
      mapper.root = Root.new(xmlname, prepare_options(options)) if xmlname
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
      prepare_args(args, block) do |type, options|
        define_accessor name
        (mapper << (type.is_a?(Class) ? Element : ElementValue).new(name, type, options)).last
      end
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
    #      include Peanuts
    #      ...
    #      elements :ration, :string, :whitespace => :collapse
    #      elements :cheeseburgers, Cheeseburger, :xmlname => :cheezburger
    #      ...
    #    end
    def elements(name, *args, &block)
      prepare_args(args, block) do |type, options|
        define_accessor name
        (mapper << (type.is_a?(Class) ? Elements : ElementValues).new(name, type, options)).last
      end
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
      prepare_args(args, nil, :xmlns => nil) do |type, options|
        define_accessor name
        mapper << Attribute.new(name, type, options)
      end
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
    def _restore(reader)
      mapper.restore(nut = new, reader)
      nut
    end

    def _save(nut, writer)
      mapper.save(nut, writer)
    end

    def prepare_args(args, blk, defopt = nil)
      type, options = *args
      type, options = (blk ? Class.new : :string), type if type.nil? || type.is_a?(Hash)
      options ||= {}
      options = defopt.merge(options) if defopt
      options = prepare_options(options)
      m = yield(type, options)
      Peanuts.init(type, mapper.namespaces, m.xmlns, &blk) if blk
      m
    end

    def prepare_options(options)
      ns = options.fetch(:xmlns) {|k| options[k] = root && root.xmlns || mapper.default_ns }
      if ns.is_a?(Symbol)
        raise ArgumentError, "undefined prefix: #{ns}" unless options[:xmlns] = mapper.namespaces[ns]
        options[:prefix] = ns
      end
      options
    end

    def define_accessor(name)
      if method_defined?(name) || method_defined?("#{name}=")
        raise ArgumentError, "#{name.inspect}: name already defined or reserved"
      end
      attr_accessor name
    end
  end

  # See also +ClassMethods+
  module InstanceMethods
    def parse(source, options = {})
      backend.parse(source, options) {|node| parse_node(node) }
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
end
