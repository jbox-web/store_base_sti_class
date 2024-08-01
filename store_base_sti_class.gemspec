# frozen_string_literal: true

require_relative 'lib/store_base_sti_class/version'

Gem::Specification.new do |s|
  s.name        = 'store_base_sti_class'
  s.version     = StoreBaseSTIClass::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Rodriguez']
  s.email       = ['nico@nicoladmin.fr']
  s.homepage    = 'https://github.com/jbox-web/store_base_sti_class'
  s.summary     = <<~MSG
    Modifies ActiveRecord 5.0.x - 7.0.x with the ability to store the actual class (instead of the base class) in
    polymorhic _type columns when using STI.
  MSG

  s.description = <<~MSG
    ActiveRecord has always stored the base class in polymorphic _type columns when using STI. This can have non-trivial
    performance implications in certain cases. This gem adds the 'store_base_sti_class' configuration option which
    controls whether ActiveRecord will store the base class or the actual class. Defaults to true for backwards
    compatibility.'
  MSG

  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0.0'

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency('activerecord', ['>= 6.1', '< 7.2'])

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'rake'

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0")
    s.add_development_dependency "base64"
    s.add_development_dependency "bigdecimal"
    s.add_development_dependency "mutex_m"
    s.add_development_dependency "drb"
    s.add_development_dependency "logger"
  end
end
