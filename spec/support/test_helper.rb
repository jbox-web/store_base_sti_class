# frozen_string_literal: true

module TestHelper
  # rubocop:disable Style/ZeroLengthPredicate
  def assert_queries(num = 1, options = {}) # rubocop:disable Metrics/MethodLength
    ignore_none = options.fetch(:ignore_none) { num == :any }
    ActiveRecord::SQLCounter.clear_log
    yield
  ensure
    the_log = ignore_none ? ActiveRecord::SQLCounter.log_all : ActiveRecord::SQLCounter.log
    if num == :any
      assert_operator the_log.size, :>=, 1, '1 or more queries expected, but none were executed.'
    else
      mesg = "#{the_log.size} instead of #{num} queries were executed.#{the_log.size == 0 ? '' : "\nQueries:\n#{the_log.join("\n")}"}"

      expect(the_log.size).to eq(num), mesg
    end
  end
  # rubocop:enable Style/ZeroLengthPredicate

  def assert_no_queries(&block)
    assert_queries(0, ignore_none: true, &block)
  end
end
