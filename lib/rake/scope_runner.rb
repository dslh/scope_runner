# encoding: utf-8
require 'tmpdir'
require 'ruby-prof'

module Rack
  # Integrates ruby prof with scope runner, generating profiles for each individual request
  # in a test suite, or a single profile for the suite as a whole. Scope runner sneaks headers
  # into API requests so that this rack mount knows when a suite begins and ends.
  #
  # This class is adapted from Rack::RubyProf. See LICENSE for attribution.
  class ScopeRunner
    def initialize(app, options = {})
      @app = app
      @options = options
      @options[:min_percent] ||= 1

      @tmpdir = options[:path] || Dir.tmpdir
      FileUtils.mkdir_p(@tmpdir)

      @printer_klasses = @options[:printers]  || {::RubyProf::FlatPrinter => 'flat.txt',
                                                  ::RubyProf::GraphPrinter => 'graph.txt',
                                                  ::RubyProf::GraphHtmlPrinter => 'graph.html',
                                                  ::RubyProf::CallStackPrinter => 'call_stack.html'}

      @skip_paths = options[:skip_paths] || [%r{^/assets}, %r{\.(css|js|png|jpeg|jpg|gif)$}]
      @only_paths = options[:only_paths]
    end

    def call(env)
      request = Rack::Request.new(env)
      sequence_number = request.env['HTTP_SCOPE_RUNNER_SEQUENCE']
      return @app.call(env) unless sequence_number && should_profile?(request.path)

      begin
        case request.env['HTTP_SCOPE_RUNNER_PROFTYPE']
        when 'request'
          result = nil

          data = ::RubyProf::Profile.profile(profiling_options) do
            result = @app.call(env)
          end

          path = sequence_number + request.path.gsub('/', '-')
          print(data, path)
        when 'suite'
          ::RubyProf.start
          result = @app.call(env)
          ::RubyProf.pause

          # Drain parameter will be given with the last request of a suite.
          drain_path = request.env['HTTP_SCOPE_RUNNER_DRAIN']
          if drain_path
            data = ::RubyProf.stop
            print(data, drain_path)
          end
        end
        result
      end
    end

    private

    def should_profile?(path)
      return false if paths_match?(path, @skip_paths)

      @only_paths ? paths_match?(path, @only_paths) : true
    end

    def paths_match?(path, paths)
      paths.any? { |skip_path| skip_path =~ path }
    end

    def profiling_options
      options = {}
      options[:measure_mode] = ::RubyProf.measure_mode
      options[:exclude_threads] =
        if @options[:ignore_existing_threads]
          Thread.list.select{|t| t != Thread.current}
        else
          ::RubyProf.exclude_threads
        end
      if @options[:request_thread_only]
        options[:include_threads] = [Thread.current]
      end
      if @options[:merge_fibers]
        options[:merge_fibers] = true
      end
      options
    end

    def print(data, path)
      @printer_klasses.each do |printer_klass, base_name|
        printer = printer_klass.new(data)

        if base_name.respond_to?(:call)
          base_name = base_name.call
        end

        if printer_klass == ::RubyProf::MultiPrinter
          printer.print(@options.merge(:profile => "#{path}-#{base_name}"))
        elsif printer_klass == ::RubyProf::CallTreePrinter
          printer.print(@options.merge(:profile => "#{path}-#{base_name}"))
        else
          file_name = ::File.join(@tmpdir, "#{path}-#{base_name}")
          ::File.open(file_name, 'wb') do |file|
            printer.print(file, @options)
          end
        end
      end
    end
  end
end