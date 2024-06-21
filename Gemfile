# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.0"

gem "rails", "~> 7.0.1"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "jsbundling-rails"

gem "turbo-rails" # [https://turbo.hotwired.dev]
gem "stimulus-rails" # [https://stimulus.hotwired.dev]

gem "cssbundling-rails"
gem "slim-rails"
gem "jbuilder"
gem "interactor-rails"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

gem "bootsnap", require: false

# Use Sass to process CSS
# gem "sassc-rails"

gem "quickbooks-ruby"
gem "rexml"
gem "lograge"
gem "whenever", require: false

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails", "~> 5.0"
  gem "factory_bot_rails"
  gem "timecop"
end

group :development do
  gem "web-console"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec"

  gem "capistrano", "~> 3.10", require: false
  gem "capistrano-rails", "~> 1.6", require: false
  gem "capistrano-rbenv", "~> 2.2", require: false
  gem "capistrano-bundler", "~> 2.0", require: false
  gem "capistrano-passenger", require: false
  gem "ed25519", ">= 1.2", "< 2.0"
  gem "bcrypt_pbkdf", ">= 1.0", "< 2.0"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
