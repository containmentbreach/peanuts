require 'libxml'
require 'forwardable'
require 'peanuts/xml/stream/reader'

module Peanuts
  module XML
    module Stream
      class LibXMLReader < Reader
        extend Forwardable

        SCHEMAS = {:xmlschema => :schema, :relaxng => :relax_ng}

        RD = LibXML::XML::Reader

        NODE_TYPES = [
          nil,
          :element,
          :attribute,
          :text,
          :cdata,
          :entity_reference,
          :entity,
          :processing_instruction,
          :comment,
          :document,
          :document_type,
          :document_fragment,
          :notation,
          :whitespace,
          :significant_whitespace,
          :end_element,
          :end_entity,
          :xml_declaration
        ]

        def initialize(source, options = {})
          super
          @footprint = Footprint.new(self)
          @reader = LibXML::XML::Reader.send(source.type, source.source)
          @reader.send("#{SCHEMAS[schema.type]}_validate", schema.schema) if @schema
        end

        def close
          @reader.close
        end

        def_delegators :@reader, :name, :local_name, :namespace_uri, :value, :depth
        def_delegator :@reader, :read_string, :read_text

        def node_type
          NODE_TYPES[@reader.node_type]
        end

        def footprint
          @footprint
        end

        def each
          yield self while read
        ensure
          close
        end

        def each_subtree_node
          depth = self.depth
          yield self while read && self.depth > depth
        end

        def subtree
          enum_for(:each_subtree_node)
        end

        def read
          case @reader.node_type
          when RD::TYPE_ATTRIBUTE
            @reader.move_to_next_attribute > 0 || @reader.read
          else
            @reader.move_to_first_attribute > 0 || @reader.read
          end
        end

        private
        class Footprint
          extend Forwardable
          include Peanuts::XML::Footprint

          def initialize(reader)
            @reader = reader
          end

          def_delegator :@reader, :node_type
          def_delegator :@reader, :local_name, :name
          def_delegator :@reader, :namespace_uri, :ns
        end
      end
    end
  end
end
