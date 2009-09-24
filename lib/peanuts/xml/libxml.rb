require 'libxml'
require 'forwardable'
require 'peanuts/xml/reader'

module Peanuts
  module XML
    module LibXML
      class Writer < Peanuts::XML::Writer
        def initialize(dest, dest_type, options = {})
          @dest_type = dest_type
          @dest = case dest_type
          when :string
            dest || ''
          when :io
            dest
          when :document
            dest || LibXML::XML::Document.new
          else
            raise ArgumentError, "unrecognized destination type #{dest_type.inspect}"
          end
        end

        def result
          @dest
        end

        attr_writer :value

        def clear
          @node_type = @local_name = @namespace_uri = @prefix = @value = nil
        end

        def write(node_type, local_name = nil, namespace_uri = nil, prefix = nil)
          if @node_type
            mknode
          else
            @node = nil
          end

          @node_type = node_type
          @local_name, @namespace_uri, @prefix = local_name, namespace_uri, prefix && prefix.to_s

          exparent, @parent = @parent, @node

          yield self

          if @node_type
            mknode
          end
          @node = nil

          if exparent.nil?
            case @dest_type
            when :string, :io
              @dest << @parent.to_s
            when :document
              @dest.root = @parent
            end
          end

          @parent = exparent
        end

        private
        def mknode
          @node = case @node_type
          when :element
            n = ::LibXML::XML::Node.new(@local_name, @value)
            if @namespace_uri
              ns = @parent && @parent.namespaces.find_by_href(@namespace_uri)
              n.namespaces.namespace = ns && ns.prefix == @prefix ? ns : ::LibXML::XML::Namespace.new(n, @prefix, @namespace_uri)
            end
            @parent << n if @parent
            n
          when :attribute
            ::LibXML::XML::Attr.new(@parent, @local_name, @value, @namespace_uri)
          else
            raise "unsupported node type #{@node_type.inspect}"
          end
          clear
        end
      end

      class Reader < Peanuts::XML::Reader
        extend Forwardable

        SCHEMAS = {:xml_schema => :schema, :relax_ng => :relax_ng}

        RD = ::LibXML::XML::Reader

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

        DEFAULT_PARSER_OPTIONS = {
          :libxml_encoding => ::LibXML::XML::Encoding::UTF_8,
          :libxml_options => ::LibXML::XML::Parser::Options::NOENT
        }

        def initialize(source, source_type, options = {})
          super()
          options = options.dup
          @schema = options.delete(:schema)
          @reader = case source_type
          when :string
            RD.string(source, parser_opt(options))
          when :io
            RD.io(source, parser_opt(options))
          when :uri
            RD.file(source, parser_opt(options))
          when :document
            RD.document(source)
          else
            raise ArgumentError, "unrecognized source type #{source_type}"
          end
          @reader.send("#{SCHEMAS[schema.type]}_validate", schema.schema) if @schema
        end

        def close
          @reader.close
        end

        def_delegators :@reader, :name, :local_name, :namespace_uri, :depth

        def node_type
          NODE_TYPES[@reader.node_type]
        end

        def value
          case @reader.node_type
          when RD::TYPE_ELEMENT
            @reader.read_string
          else
            @reader.has_value? ? @reader.value : nil
          end
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
          until @reader.node_type == RD::TYPE_ELEMENT
            return nil unless read
          end
          self
        end

        private
        def parser_opt(options)
          h = DEFAULT_PARSER_OPTIONS.merge(options)
          h.merge(h.from_namespace!(:libxml))
        end

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

      def self.schema(schema_type, source, source_type = :string)
        schema_class = case schema_type
        when :xml_schema
          ::LibXML::XML::Schema
        when :relax_ng
          ::LibXML::XML::RelaxNG
        else
          raise ArgumentError, "unrecognized schema type #{schema_type}"
        end
        schema = case source_type
        when :string
          schema_class.string(source)
        when :io
          schema_class.string(source.read)
        when :uri
          schema_class.new(source)
        when :document
          schema_class.document(source)
        else
          raise ArgumentError, "unrecognized source type #{source_type}"
        end

        Schema.new(schema_type, schema)
      end

      class Schema
        attr_reader :type, :handle

        def initialize(type, handle)
          @type, @handle = type, handle
        end
      end
    end
  end
end
