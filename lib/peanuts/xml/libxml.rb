require 'libxml'
require 'forwardable'
require 'peanuts/xml/reader'

module Peanuts
  module XML
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
      ].freeze

      def initialize(source, options = {})
        super
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

      def each
        depth = self.depth
        if read
          while self.depth > depth
            yield self
            break unless next_sibling
          end
        end
      end

      def find_element
        read until @reader.node_type == RD::TYPE_ELEMENT
        self
      end

      private
      def read
        case @reader.node_type
        when RD::TYPE_ATTRIBUTE
          @reader.move_to_next_attribute > 0 || @reader.read
        else
          @reader.move_to_first_attribute > 0 || @reader.read
        end
      end

      def next_sibling
        case @reader.node_type
        when RD::TYPE_ATTRIBUTE
          @reader.move_to_next_attribute > 0 || @reader.read
        else
          @reader.next > 0
        end
      end
    end
  end
end
