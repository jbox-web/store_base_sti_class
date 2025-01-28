# frozen_string_literal: true

appraise 'activerecord_7.1' do
  gem 'activerecord', '~> 7.1.0'

  # Fix:
  # warning: logger was loaded from the standard library, but will no longer be part of the default gems since Ruby 3.5.0
  # Add logger to your Gemfile or gemspec.
  install_if '-> { Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0") }' do
    gem 'logger'
  end
end

appraise 'activerecord_7.2' do
  gem 'activerecord', '~> 7.2.0'
end

appraise 'activerecord_8.0' do
  gem 'activerecord', '~> 8.0.0'
end
