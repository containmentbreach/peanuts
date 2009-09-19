module Peanuts
  module XML
    module Footprint
      def eql?(other)
        self.equal?(other) || other && node_type == other.node_type && name == other.name && ns == other.ns
      end

      def hash
        node_type.hash ^ name.hash ^ ns.hash
      end

      def to_s
        "#{node_type}(#{name}, #{ns})"
      end
    end
  end
end
