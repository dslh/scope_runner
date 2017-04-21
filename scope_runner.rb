#!/usr/bin/env ruby
require_relative 'lib/scope_runner'

require 'yaml'
require 'pry-byebug'

# RestClient.log = 'stdout'

if $0 == __FILE__
  suites = ScopeRunner.read_runscope_export './scopes.json'
  # suites.each { |suite| puts suite.to_s ; puts }

  vars = YAML.load(File.read('./env.yaml'))['vars']
  suites[1].run vars
end
