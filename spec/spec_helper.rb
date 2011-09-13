require 'intermodal'
require 'rails'
require 'rspec-rails'
require 'ap' # Debugging

# Usage:
# variable_to_watch.tap(&WATCH)
WATCH = lambda { |o| ap o } unless defined?(WATCH)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.filter_run_excluding :external => true
  config.run_all_when_everything_filtered = true 

  # Uncomment to use with Rspec Rails
  # If you'd prefer not to run each of your examples within a transaction,
  # uncomment the following line.
  #config.use_transactional_examples false
end
