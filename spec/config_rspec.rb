# frozen_string_literal: true

# Configure RSpec
RSpec.configure do |config|
  config.include TestHelper

  config.color = true
  config.fail_fast = false

  # Run tests in random order
  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!
end
