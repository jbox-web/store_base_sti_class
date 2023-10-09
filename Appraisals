# frozen_string_literal: true

RAILS_VERSIONS = %w[
  6.1.7
  7.0.8
  7.1.0
].freeze

RAILS_VERSIONS.each do |version|
  appraise "activerecord_#{version}" do
    gem 'activerecord', version
  end
end
