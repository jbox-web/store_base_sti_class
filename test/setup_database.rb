# frozen_string_literal: true

require 'schema'

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
ActiveRecord::Base.logger = Logger.new('test/test.log')

# Re-create test database
ActiveRecord::Tasks::DatabaseTasks.drop_current
ActiveRecord::Tasks::DatabaseTasks.create_current

Schema.up
