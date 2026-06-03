ENV['RAILS_ENV'] ||= 'test'

require "bundler/setup"
require "database_cleaner"

begin
  require File.expand_path('../dummy/config/environment', __FILE__)
rescue LoadError
  puts 'Could not load dummy application. Please ensure you have run `bundle exec rake test_app`'
  exit
end

# The Solidus 2.11 generator + chained db:create/db:migrate populates the dummy
# app's schema.rb but can leave the sqlite database file empty, so the spree_*
# tables are missing at spec time. maintain_test_schema! loads schema.rb into the
# database -- the standard rails_helper recovery for a stale/empty test schema.
require "active_record"
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.disable_monkey_patching!
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = "random"
  Kernel.srand config.seed

  config.before :suite do
    DatabaseCleaner.strategy = :transaction
  end

  config.before :each do
    DatabaseCleaner.start
  end

  # After each spec clean the database.
  config.after :each do
    DatabaseCleaner.clean
  end
end
