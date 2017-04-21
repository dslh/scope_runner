module ScopeRunner
  class Suite
    attr_accessor :name, :version, :steps, :trigger

    def self.from_json_array(runscope_export)
      runscope_export.map { |suite_object| from_json(suite_object) }
    end

    def self.from_json(suite_object)
      new.tap do |suite|
        suite.trigger = suite_object['trigger_url'][%r((?<=/)[-a-z0-9]+(?=/trigger))]
        suite.name = suite_object['name']
        suite.version = suite_object['version']
        suite.steps = Step.from_json_array(suite_object['steps'])
      end
    end

    def run(vars, proftype)
      puts "Running #{name} (#{trigger}) in #{proftype} mode..."
      steps.each_index do |index|
        step = steps[index]
        step.run(vars, trigger, index, proftype, first: step == steps.first, last: step == steps.last)
      end
    end

    def to_s
      <<~EOS
        #{name} (#{version}) #{trigger}
        #{steps.count} steps:
        #{steps.map(&:to_s).join("\n\n")}
      EOS
    end
  end
end
