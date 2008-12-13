require 'rexml/document'
require 'time'
require 'xmlnuts/converters'
require 'xmlnuts/mappings'

module XmlNuts
  module Nut
    def self.included(other) #:nodoc:
      other.extend(ClassMethods)
    end

    module ClassMethods
      def element(name, type = :string, options = {})
        mappings << ElementMapping.new(name, type, options)
        attr_accessor name
      end

      def attribute(name, type = :string, options = {})
        mappings << AttributeMapping.new(name, type, options)
        attr_accessor name
      end

      def has_one(name, type, options = {})
        mappings << HasOneMapping.new(name, type, options)
        attr_accessor name
      end

      def mappings
        @mappings ||= []
      end

      def build(nut, destination = nil)
        case destination
        when nil
          destination = REXML::Document.new
          e = destination.add_element('root')
          build_node(nut, e)
        when REXML::Node
          build_node(nut, destination)
        end
        destination
      end

      def parse(source)
        case source
        when nil
          nil
        when REXML::Node
          parse_node(new, source)
        when String
          doc = REXML::Document.new(source)
          (root = doc.root) ? parse_node(new, root) : nil
        end
      end

      private
      def build_node(nut, node)
        callem(:to_xml, nut, node)
        node
      end

      def parse_node(nut, node) #:nodoc:
        callem(:from_xml ,nut, node)
        nut
      end

      def callem(method, nut, node) #:nodoc:
        mappings.each {|m| m.send(method, nut, node) }
      end
    end
  end
end
