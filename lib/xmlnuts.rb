require 'rexml/document'
require 'time'
require 'converters'
require 'mappings'
#require 'rubygems'
#require 'shoulda'

module XmlNuts
  module Nut
    def self.included(other)
      other.extend(NutClassMethods)
    end
  end

  module NutClassMethods
    def element(name, type = String, options = {})
      mappings << ElementMapping.new(name, type, options)
      attr_accessor name
    end

    def attribute(name, type = String, options = {})
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

    def _build_node(nut, node)
      _callem(:to_xml, nut, node)
      node
    end

    def _parse_node(nut, node)
      _callem(:from_xml ,nut, node)
      nut
    end

    def _callem(method, nut, node)
      mappings.each {|m| m.send(method, nut, node) }
    end

    def build(nut, destination = nil)
      case destination
      when nil
        destination = REXML::Document.new
        e = destination.add_element('root')
        _build_node(nut, e)
      when REXML::Node
        _build_node(nut, destination)
      end
      destination
    end

    def parse(source)
      case source
      when nil
        nil
      when REXML::Node
        _parse_node(new, source)
      when String
        doc = REXML::Document.new(source)
        (root = doc.root) ? _parse_node(new, root) : nil
      end
    end
  end
end
