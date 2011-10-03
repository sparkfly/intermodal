$LOAD_PATH.unshift '.'

require 'intermodal'
require 'rails'
require 'active_record'
require 'will_paginate/active_record'
require 'action_controller'
require 'rspec-rails'
require 'database_cleaner'
require 'machinist/active_record'
require 'redis'
require 'ap' # Debugging
require 'pry'


# Usage:
# variable_to_watch.tap(&WATCH)
WATCH = lambda { |o| ap o } unless defined?(WATCH)

# Log to stderr
Rails.logger = ActiveSupport::BufferedLogger.new($stderr, ActiveSupport::BufferedLogger::Severity::ERROR)

# Turn this on for debugging
ActiveRecord::Migration.verbose = false

Dir["spec/support/**/*.rb"].map { |f| f.gsub(%r{.rb$}, '') }.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.filter_run_excluding :external => true
  config.run_all_when_everything_filtered = true 

  # Uncomment to use with Rspec Rails
  # If you'd prefer not to run each of your examples within a transaction,
  # uncomment the following line.
  #config.use_transactional_examples false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation # :transaction strategy currently does not work
    DatabaseCleaner.clean_with :truncation
  end

  config.before(:each)  { DatabaseCleaner.start }
  config.after(:each)   { DatabaseCleaner.clean }
end

