# frozen_string_literal: true

require 'simplecov'

# Start SimpleCov
SimpleCov.start do
  add_filter 'spec/'
end

# Load test gems
require 'active_record'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

# Load our own config
require_relative 'config_rspec'
require_relative 'rspec_patch'

# Setup DB connections
test_db_config = {
  adapter:  'postgresql',
  host:     '127.0.0.1',
  database: 'store_base_sti_class_test',
  username: 'postgres',
  password: 'postgres',
  encoding: 'utf8'
}

ActiveRecord::Tasks::DatabaseTasks.env = 'test'
ActiveRecord::Base.configurations = { 'test' => test_db_config }
ActiveRecord::Base.logger = Logger.new('spec/test.log')

# Re-create test database
ActiveRecord::Tasks::DatabaseTasks.drop_current
ActiveRecord::Tasks::DatabaseTasks.create_current

# Load schema
Schema.up

require 'store_base_sti_class'
