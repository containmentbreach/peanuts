require 'enumerator'
require 'rexml/document'
require 'time'
require 'xmlnuts/backend'
require 'xmlnuts/converters'
require 'xmlnuts/mappings'

module XmlNuts #:nodoc:
  module Nut
    def self.included(other) #:nodoc:
      other.extend(ClassMethods)
    end

    module ClassMethods
      def namespaces(options = nil)
        @namespaces ||= {}
        options ? @namespaces.update(options) : @namespaces
      end

      def element(name, type = :string, options = {})
        mappings << (type.is_a?(Class) ? ElementMapping : ElementValueMapping).new(name, type, options)
        attr_accessor name
      end

      def elements(name, type = :string, options = {})
        mappings << (type.is_a?(Class) ? ElementsMapping : ElementValuesMapping).new(name, type, options)
        attr_accessor name
      end

      def attribute(name, type = :string, options = {})
        mappings << AttributeMapping.new(name, type, options)
        attr_accessor name
      end

      def mappings
        @mappings ||= []
      end

      def build(nut, destination = nil)
        backend = REXMLBackend.new
        case destination
        when nil
          destination = REXML::Document.new
          e = destination.add_element('root')
          build_node(backend, nut, e)
        when REXML::Node
          build_node(backend, nut, destination)
        end
        destination
      end

      def parse(source, options = {})
        backend = (options[:backend] || XmlBackend.default).new
        case source
        when nil
          nil
        when REXML::Node
          parse_node(backend, new, source)
        when String
          doc = REXML::Document.new(source)
          (root = doc.root) ? parse_node(backend, new, root) : nil
        end
      end

      def build_node(backend, nut, node)
        backend.add_namespaces(node, namespaces)
        callem(:to_xml, backend, nut, node)
        node
      end

      def parse_node(backend, nut, node)
        callem(:from_xml, backend, nut, node)
        nut
      end

      private
      def callem(method, *args)
        mappings.each {|m| m.send(method, *args) }
      end
    end
  end
end
