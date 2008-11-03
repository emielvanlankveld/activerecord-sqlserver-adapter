require 'rubygems'
require 'shoulda'
require 'mocha'
require 'cases/helper'

SQLSERVER_TEST_ROOT       = File.expand_path(File.join(File.dirname(__FILE__),'..'))
SQLSERVER_ASSETS_ROOT     = SQLSERVER_TEST_ROOT + "/assets"
SQLSERVER_FIXTURES_ROOT   = SQLSERVER_TEST_ROOT + "/fixtures"
SQLSERVER_MIGRATIONS_ROOT = SQLSERVER_TEST_ROOT + "/migrations"
SQLSERVER_SCHEMA_ROOT     = SQLSERVER_TEST_ROOT + "/schema"
ACTIVERECORD_TEST_ROOT    = File.expand_path(SQLSERVER_TEST_ROOT + "/../../../../rails/activerecord/test/")

ActiveRecord::Migration.verbose = false

class TableWithRealColumn < ActiveRecord::Base; end


ActiveRecord::Base.connection.class.class_eval do
  IGNORED_SQL << /SELECT SCOPE_IDENTITY/ << /INFORMATION_SCHEMA.TABLES/ << /INFORMATION_SCHEMA.COLUMNS/
end

ActiveRecord::ConnectionAdapters::SQLServerAdapter.class_eval do
  def raw_select_with_query_record(sql, name = nil)
    $queries_executed ||= []
    $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
    raw_select_without_query_record(sql,name)
  end
  alias_method_chain :raw_select, :query_record
end

module ActiveRecord 
  class TestCase < ActiveSupport::TestCase
    def assert_sql(*patterns_to_match)
      $queries_executed = []
      yield
    ensure
      failed_patterns = []
      patterns_to_match.each do |pattern|
        failed_patterns << pattern unless $queries_executed.any?{ |sql| pattern === sql }
      end
      assert failed_patterns.empty?, "Query pattern(s) #{failed_patterns.map(&:inspect).join(', ')} not found in:\n#{$queries_executed.inspect}"
    end
  end
end


