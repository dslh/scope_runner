module ScopeRunner
  module Comparators
    def self.for(json)
      const_get(json['comparison'].split('_').map(&:capitalize).join).new(json['value'])
    end

    class Comparator
      attr_reader :comparison

      def initialize(comparison)
        @comparison = comparison
      end

      def compare?(value, vars)
        _compare? value, ScopeRunner.sub_vars(@comparison, vars)
      end
    end

    class NotEmpty < Comparator
      def _compare?(value, _)
        !(value.nil? || value.empty?)
      end
    end

    class Contains < Comparator
      def _compare?(value, expected)
        value[expected]
      end
    end

    class DoesNotContain < Comparator
      def _compare?(value, expected)
        !value[expected]
      end
    end

    class Equal < Comparator
      def _compare?(value, expected)
        value == expected
      end
    end

    class NotEqual < Comparator
      def _compare?(value, expected)
        value != expected
      end
    end

    class IsNull < Comparator
      def _compare?(value, expected)
        value.nil?
      end
    end

    class EqualNumber < Comparator
      def _compare?(value, expected)
        value.to_i == expected.to_i
      end
    end

    class IsLessThan < Comparator
      def _compare?(value, limit)
        value.to_i < limit.to_i
      end
    end

    class IsLessThanOrEqual < Comparator
      def _compare?(value, limit)
        value.to_i <= limit.to_i
      end
    end

    class IsGreaterThan < Comparator
      def _compare?(value, limit)
        value.to_i > limit.to_i
      end
    end

    class IsGreaterThanOrEqual < Comparator
      def _compare?(value, limit)
        value.to_i >= limit.to_i
      end
    end

    class HasKey < Comparator
      def _compare?(hash, key)
        hash.include? key
      end
    end

    class HasValue < Comparator
      def _compare?(hash_or_array, key)
        if hash_or_array.is_a? Hash
          hash_or_array.values.include? key
        else
          hash_or_array.inclued? key
        end
      end
    end

    class IsANumber < Comparator
      def _compare?(value, _)
        value.is_a?(Numeric) || value =~ /^-?\d+(?:\.\d+)?$/
      end
    end
  end
end
