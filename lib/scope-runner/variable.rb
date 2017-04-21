module ScopeRunner
  class Variable
    attr_accessor :name, :extractor

    def self.from_json_array(variable_array)
      variable_array.map { |variable_object| from_json(variable_object) }
    end

    def self.from_json(variable_object)
      new.tap do |variable|
        variable.name = variable_object['name']
        variable.extractor = Extractors.for variable_object
      end
    end

    def extract(response, vars)
      vars[name] = extractor.extract(response)
    end
  end
end
