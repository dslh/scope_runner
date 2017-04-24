# encoding: utf-8
require 'tmpdir'
require 'ruby-prof'
require 'memory_profiler'

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
      suite_id = request.env['HTTP_SCOPERUNNER_SUITE']
      sequence_number = request.env['HTTP_SCOPERUNNER_SEQUENCE']
      sequenced_path = sequence_number + request.path.gsub('/', '-')
      init_suite(suite_id) if request.env['HTTP_SCOPERUNNER_INIT']

      return @app.call(env) unless sequence_number && should_profile?(request.path)

      begin
        result = nil

        case request.env['HTTP_SCOPERUNNER_PROFTYPE']
        when 'request'

          data = ::RubyProf::Profile.profile(profiling_options) do
            result = @app.call(env)
          end

          print(data, ::File.join(suite_id, sequenced_path))

        when 'suite'
          ::RubyProf.start unless ::RubyProf.running?

          ::RubyProf.resume
          result = @app.call(env)
          ::RubyProf.pause

          # Drain parameter will be given with the last request of a suite.
          if request.env['HTTP_SCOPERUNNER_DRAIN']
            data = ::RubyProf.stop
            print(data, ::File.join(suite_id, 'suite'))
          end

        when 'memrequest'
          data = ::MemoryProfiler.report do
            result = @app.call(env)
          end

          print_mem(data, ::File.join(suite_id, sequenced_path))

        when 'memsuite'
          ::MemoryProfiler.start # Does nothing if already started

          result = @app.call(env)

          if request.env['HTTP_SCOPERUNNER_DRAIN']
            data = ::MemoryProfiler.stop
            print_mem(data, ::File.join(suite_id, 'suite'))
          end
        end
        result
      end
    end

    private

    def init_suite(suite_id)
      ::RubyProf.stop if ::RubyProf.running?

      init_dir = ::File.join(@tmpdir, suite_id)

      return unless ::File.directory?(init_dir)
      ::FileUtils.rm_r Dir[::File.join(init_dir, '*')]
    end

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
      ::FileUtils.mkdir_p ::File.dirname(::File.join(@tmpdir, path))

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

    def print_mem(data, path)
      full_path = ::File.join(@tmpdir, path)
      ::FileUtils.mkdir_p ::File.dirname(full_path)
      ::File.open("#{full_path}-mem.txt", 'w') { |file| data.pretty_print(file) }
    end
  end
end
