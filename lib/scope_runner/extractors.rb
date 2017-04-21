module ScopeRunner
  module Extractors
    # return an appropriate extractor, based on the `source` and optional `property` fields
    # of a runscope variable or assertion.
    def self.for(json)
      const_get(json['source'].split('_').map(&:capitalize).join).new(json['property'])
    end

    class Extractor
      def initialize(property)
        @property = property
      end
    end

    class ResponseSize < Extractor
      def extract(response)
        response.response_size
      end
    end

    class ResponseStatus < Extractor
      def extract(response)
        response.response_status
      end
    end

    class ResponseHeaders < Extractor
      def extract(response)
        response.response_headers[@property]
      end
    end

    class ResponseTime < Extractor
      def extract(response)
        response.response_time
      end
    end

    class ResponseJson < Extractor
      def extract(response)
        extract_json_value(response.response_json, @property)
      end

      private

      # See https://www.runscope.com/docs/api-testing/json-samples
      def extract_json_value(json, expression)
        expression.scan(/(?:\w+|\[-?\d+\])/).inject(json) do |json, elem|
          if elem =~ /\[(-?\d+)\]/
            json[$1.to_i]
          else
            json[elem]
          end
        end
      end
    end
  end
end
