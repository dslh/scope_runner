module ScopeRunner
  class Response
    attr_reader :response_time

    def initialize(restclient_response, response_time)
      @restclient_response = restclient_response
      @response_time = response_time
    end

    def response_status
      @restclient_response.code
    end

    def response_json
      @response_json ||= JSON.parse @restclient_response.body
    end

    def response_text
      @restclient_response.body
    end

    def response_size
      @restclient_response.body.length
    end
  end
end
