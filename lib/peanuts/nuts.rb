require 'peanuts/mappings'
require 'peanuts/mapper'
require 'peanuts/xml/reader'

module Peanuts #:nodoc:
  # See also +ClassMethods+
  def self.included(other) #:nodoc:
    other.extend(ClassMethods)
  end

  # See also +PeaNuts+.
  module ClassMethods
    include Mappings

    def self.extended(other)
      other.instance_eval do
        @mappings = Mapper.new
      end
    end

    #    mappings -> Mapper
    #
    # Returns all mappings defined on a class.
    attr_reader :mappings

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
    def namespaces(mappings = nil)
      mappings ? @mappings.namespaces.update(mappings) : @mappings.namespaces
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
      @mappings.root = Root.new(xmlname, prepare_options(options)) if xmlname
      @mappings.root
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
    def element(name, type = :string, options = {}, &block)
      prepare_args(type, options, block) do |type, options|
        define_accessor name
        (@mappings << (type.is_a?(Class) ? Element : ElementValue).new(name, type, options)).last
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
    def elements(name, type = :string, options = {}, &block)
      prepare_args(type, options, block) do |type, options|
        define_accessor name
        (@mappings << (type.is_a?(Class) ? Elements : ElementValues).new(name, type, options)).last
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
    def attribute(name, type = :string, options = {})
      define_accessor name
      @mappings << Attribute.new(name, type, prepare_options({:xmlns => nil}.merge(options)))
    end

    def schema(schema = nil)
      @mappings.schema = schema if schema
      @mappings.schema
    end

    def restore(reader)
      e = reader.find_element
      e && _restore(e)
    end

    def restore_from(source_type, source, options = {})
      restore(XML::Reader.new(source_type, source, options))
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

    def parse_events(nut, events) #:nodoc:
      @mappings.parse(nut, events)
    end

    private
    def _restore(events)
      nut = new
      @mappings.parse(nut, events)
      nut
    end

    def prepare_args(type, options, blk)
      if blk
        options = prepare_options(type) if type.is_a?(Hash)
        type = Class.new
        yield(type, options).tap do |m|
          type.instance_eval do
            include Peanuts
            mappings.set_context(m, namespaces)
            instance_eval(&blk)
          end
        end
      else
        options = prepare_options(options)
        yield type, options
      end
    end

    def prepare_options(options)
      ns = options.fetch(:xmlns) {|k| options[k] = root && root.xmlns || @mappings.container && @mappings.container.xmlns }
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
