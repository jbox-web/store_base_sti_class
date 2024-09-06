# frozen_string_literal: true

module RSpecPatch
  module Expectations
    def expectation_count
      @expectation_count ||= 0
    end

    def update_expectation_count
      @expectation_count = expectation_count + 1
    end
  end

  module Matchers
    def expect(*args, &block)
      RSpec::Expectations.update_expectation_count
      super
    end
  end

  module SummaryNotification
    def totals_line(*args)
      text = super
      count = RSpec::Expectations.expectation_count
      message = RSpec::Core::Formatters::Helpers.pluralize(count, 'expectation')
      "#{text.chomp}, #{message}"
    end
  end
end

unless RSpec::Expectations.respond_to?(:expectation_count)
  RSpec::Expectations.extend(RSpecPatch::Expectations)
  RSpec::Matchers.prepend(RSpecPatch::Matchers)
  RSpec::Core::Notifications::SummaryNotification.prepend(RSpecPatch::SummaryNotification)
end
