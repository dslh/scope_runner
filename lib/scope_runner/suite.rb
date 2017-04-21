module ScopeRunner
  class Suite
    attr_accessor :name, :version, :steps

    def self.from_json_array(runscope_export)
      runscope_export.map { |suite_object| from_json(suite_object) }
    end

    def self.from_json(suite_object)
      new.tap do |suite|
        suite.name = suite_object['name']
        suite.version = suite_object['version']
        suite.steps = Step.from_json_array(suite_object['steps'])
      end
    end

    def run(vars)
      puts "Running #{name}..."
      steps.each { |step| step.run(vars) }
    end

    def to_s
      <<~EOS
        #{name} (#{version})
        #{steps.count} steps:
        #{steps.map(&:to_s).join("\n\n")}
      EOS
    end
  end
end
