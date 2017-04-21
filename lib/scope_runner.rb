require 'json'
require 'rest-client'
require 'colorize'

module ScopeRunner
  INLINE_VARIABLE = /{{[^}]+}}/

  def self.read_runscope_export(path)
    Suite.from_json_array JSON.parse File.read path
  end

  def self.scrape_variables(str)
    return [] if str.nil? || !str.is_a?(String)

    str.scan(INLINE_VARIABLE).map { |s| s[2...-2] }.to_a
  end

  def self.sub_vars(str, vars)
    return nil if str.nil?

    str.gsub(INLINE_VARIABLE) { |var| vars[var[2...-2]] }
  end
end

require_relative 'scope_runner/suite'
require_relative 'scope_runner/step'
require_relative 'scope_runner/variable'
require_relative 'scope_runner/assertion'
require_relative 'scope_runner/extractors'
require_relative 'scope_runner/comparators'
require_relative 'scope_runner/response'
