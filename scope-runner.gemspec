# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)
require 'scope-runner/version'

Gem::Specification.new do |s|
  s.name     = 'scope-runner'
  s.version  = ScopeRunner::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors  = ['Doug Hammond']
  s.email    = ['douglas@gohiring.com']
  s.homepage = 'https://github.com/dslh/scope_runner'
  s.summary  = 'ScopeRunner runs RunScope scopes'
  s.license  = 'BSD-2-Clause'

  s.required_ruby_version = '>= 2.2.6'
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.executables = ['scope_runner.rb']
  s.files = Dir['lib/**/*', 'bin/*', 'LICENSE', 'README.md']
  s.add_runtime_dependency 'ruby-prof'
  s.add_runtime_dependency 'memory_profiler'
  s.add_runtime_dependency 'rake'
  s.add_runtime_dependency 'trollop'
  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'colorize'
end
