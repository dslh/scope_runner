module ScopeRunner
  class Step
    attr_accessor :url, :method, :body, :step_type, :note,
      :form, :variables, :args, :headers, :auth,
      :assertions, :scripts

    def self.from_json_array(step_array)
      step_array.map { |step_object| from_json(step_object) }
    end

    def self.from_json(step_object)
      new.tap do |step|
        step.url = step_object['url']
        step.method = step_object['method']
        step.body = step_object['body']
        step.step_type = step_object['step_type']
        step.note = step_object['note']
        step.scripts = step_object['scripts']
        step.auth = step_object['auth']

        # Runscope allows multiple values for the same header. We only take the first.
        step.headers = Hash[step_object['headers'].map { |header, values| [header, values.first] }]
        # Unbox singular or empty values.
        step.form = Hash[step_object['form'].map do |param, values|
          [param, values.size > 1 ? values : values.first]
        end] if step_object['form']
        step.variables = Variable.from_json_array(step_object['variables'])
        step.assertions = Assertion.from_json_array(step_object['assertions'])
      end
    end

    def run(vars, suite, index, proftype, first:, last:)
      puts "- #{step_type}: #{method} #{url_suffix(vars)}"
      check_vars(vars)
      response = fire_request(vars, suite, index, proftype, first, last)
      run_assertions(response, vars)
      extract_vars(response, vars)
    end

    def required_variables
      (
        ScopeRunner.scrape_variables(url) +
        ScopeRunner.scrape_variables(body) +
        scrape_header_variables +
        scrape_assertion_variables +
        scrape_form_variables
      ).sort.uniq
    end

    def to_s
      <<~EOS
        #{step_type} #{method} #{url}
        Variables: #{required_variables.join ' '}
      EOS
    end

    def url_suffix(vars)
      ScopeRunner.sub_vars(url, vars).sub %r(^https?://[^/]*), ''
    end

    private

    def check_vars(vars)
      missing_variables = required_variables - vars.keys
      return if missing_variables

      puts "Missing variables: #{missing_variables.join ', '}".red
    end

    def fire_request(vars, suite, index, proftype, first, last)
      start = Time.now
      headers = sub_header_variables(vars).merge(
        'ScopeRunner-Proftype' => proftype,
        'ScopeRunner-Suite'    => suite,
        'ScopeRunner-Sequence' => index
      )
      headers.merge!('ScopeRunner-Init' => 'true') if first
      headers.merge!('ScopeRunner-Drain' => 'true') if last

      payload = if !(body.nil? || body.empty?)
                  headers = headers.merge(content_type: :json)
                  ScopeRunner.sub_vars(body, vars)
                else
                  payload = sub_form_variables(vars)
                end

      restclient_response = RestClient::Request.execute(
                              method: method.downcase.to_sym,
                              url: ScopeRunner.sub_vars(url, vars),
                              payload: payload,
                              headers: headers
                            )
      response_time = ((Time.now - start) * 1000.0).to_i
      Response.new(restclient_response, response_time)
    rescue RestClient::Exception => e
      puts e.message
      puts e.response.body
      raise
    end

    def run_assertions(response, vars)
      failures = assertions.reject { |assertion| assertion.run(response, vars) }
      if failures.empty?
        puts "  #{assertions.size} assertions passed".green
      else
        puts "  #{failures.size} of #{assertions.size} failed".red
      end
    end

    def extract_vars(response, vars)
      variables.each { |variable| variable.extract(response, vars) }
    end

    def scrape_header_variables
      headers.map do |header, value|
        ScopeRunner.scrape_variables(header) +
          ScopeRunner.scrape_variables(value)
      end.flatten
    end

    def sub_header_variables(vars)
      Hash[headers.map do |header, value|
        [ScopeRunner.sub_vars(header, vars), ScopeRunner.sub_vars(value, vars)]
      end]
    end

    def sub_form_variables(vars)
      return {} if form.nil?

      Hash[form.map do |param, values|
        [
          ScopeRunner.sub_vars(param, vars),
          if values.is_a? Array
            values.map { |value| ScopeRunner.sub_vars(value, vars) }
          else
            ScopeRunner.sub_vars(values, vars)
          end
        ]
      end]
    end

    def scrape_assertion_variables
      assertions.map { |assertion| assertion.required_variables }.flatten
    end

    def scrape_form_variables
      return [] if form.nil?

      form.map do |param, values|
        ScopeRunner.scrape_variables(param) +
          if values.is_a? Array
            values.map { |value| ScopeRunner.scrape_variables(value) }
          else
            [ScopeRunner.scrape_variables(values)]
          end
      end.flatten
    end
  end
end
