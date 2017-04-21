module ScopeRunner
  class Assertion
    attr_accessor :comparator, :extractor

    def self.from_json_array(assertion_array)
      assertion_array.map { |assertion_object| from_json(assertion_object) }
    end

    def self.from_json(assertion_object)
      new.tap do |assertion|
        assertion.extractor = Extractors.for assertion_object
        assertion.comparator = Comparators.for assertion_object
      end
    end

    def required_variables
      ScopeRunner.scrape_variables(comparator.comparison)
    end

    def run(response, vars)
      comparator.compare? extractor.extract(response), vars
    end
  end
end
