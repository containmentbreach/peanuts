module XmlNuts
  module XmlBackend
    class REXMLBackend
      def add_namespaces(context, namespaces)
        namespaces.each {|prefix, uri| context.add_namespace(prefix.to_s, uri) }
      end

      def each_element_with_value(context, name, ns, &block)
        REXML::XPath.each(context, "ns:#{name}", 'ns' => ns) {|el| yield el, el.text }
      end

      def attribute(context, name, ns)
        name, ns = to_prefixed_name(context, name, ns, true)
        context.attributes[name]
      end

      def set_attribute(context, name, ns, text)
        name, ns = to_prefixed_name(context, name, ns, true)
        context.add_attribute(name, text)
      end

      def add_element(context, name, ns, text)
        name, ns = to_prefixed_name(context, name, ns, false)
        elem = context.add_element(name)
        elem.add_namespace(ns) if ns
        elem.text = text if text
        elem
      end

      def to_prefixed_name(context, name, ns, prefix_required)
        if ns
          if prefix = context.namespaces.invert[ns]
            name, ns = "#{prefix}:#{name}", nil
          else
            raise ArgumentError, "no prefix defined for #{ns}" if prefix_required
          end
        end
        return name, ns
      end
    end

    def self.default
      @@default
    end

    def self.default=(backend)
      @@default = backend
    end

    self.default = REXMLBackend
  end
end
