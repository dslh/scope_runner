#!/usr/bin/env ruby
require 'rubygems'
require 'pry-byebug'
require_relative '../lib/scope-runner'

require 'yaml'
require 'trollop'

opts = Trollop::options do
  version "ScopeRunner #{ScopeRunner::VERSION} (c) 2017 Doug Hammond"
  banner <<~EOS
    Usage: #{__FILE__} [options] scopes.json

    Runs one or more RunScope test suites defined in the given "scopes" file.
    The file should be in the format returned by the RunScope API test export
    facility. By default all suites are run in the order defined in the file,
    but individual suites may be selected based on cardial order in the file,
    or their trigger ID.
  EOS

  opt :env,
      'A YAML file containing a hash named "vars", to be used as the initial suite variables.',
      type: :string
  opt :suite_number, 'The cardinal position of the suite to run.', type: :integers
  opt :suite_trigger, 'The trigger ID of the suite to run.', type: :strings
  opt :proftype, "One of #{ScopeRunner::PROFTYPES.join ' or '}. For use with Rack::ScopeRunner", default: 'suite'
  opt :verbose, 'Log HTTP requests made by rest-client.'
  opt :list, 'Print a listing of suites in the scopefile to stdout and exit.'
end
Trollop::die 'No scope file given' if ARGV.empty?
Trollop::die 'Invalid proftype' unless ScopeRunner::PROFTYPES.include? opts[:proftype]
all_scopes = ScopeRunner.read_runscope_export ARGV.shift
if opts[:list]
  all_scopes.each { |suite| puts suite.to_s ; puts }
  exit 0
end

RestClient.log = 'stdout' if opts[:verbose]

vars = opts[:env] ? YAML.load(File.read(opts[:env]))['vars'] : {}
scopes = opts[:suite_number]&.map { |index| all_scopes[index] }
if opts[:suite_trigger]
  scopes += all_scopes.select { |scope| opts[:suite_trigger].include? scope.trigger }
end
scopes = all_scopes if scopes.empty?
scopes.each { |scope| scope.run vars, opts[:proftype] }
