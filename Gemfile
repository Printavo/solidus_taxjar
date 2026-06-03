source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Consume Printavo's Solidus fork (Solidus 2.11.16 + Rails 8 compat + state_machines
# pin). Works on both the Rails 7.2 and Rails 8.0 axes.
gem "solidus", git: "https://github.com/Printavo/solidus.git", branch: "rails-8.0-support"

if ENV['RAILS_VERSION']
  # Was ENV['RAILS_VERSON'] (typo): the requested Rails version was silently
  # dropped, so the dummy app always resolved against whatever railties the
  # Solidus dependency pulled in rather than the axis under test.
  gem "rails", ENV['RAILS_VERSION'], require: false
end

# ENV.fetch('DB') with no default raises KeyError when DB is unset; the dummy app
# defaults to sqlite, so default to sqlite and only pull pg when explicitly asked.
if ENV.fetch('DB', nil) == 'postgres'
  gem 'pg'
else
  # The dummy app uses sqlite by default but the gem was never declared as a
  # dependency, so the generated dummy could not connect.
  gem 'sqlite3'
end

group :development, :test do
  gem "pry"

  # Test-harness modernization for Rails 7.2/8.0 on Ruby 3.4.
  # rspec-rails 8.x removed fixture_path=, which the Solidus 2.11 dummy relies on.
  gem "rspec-rails", "~> 7.1"
  gem "database_cleaner", "~> 2.0"
  gem "sprockets", "~> 4"
  # Ruby 3.4 extracted these from stdlib into bundled/default gems; pin them
  # explicitly so they resolve when the dummy app and Rails reference them.
  gem "mutex_m"
  gem "benchmark"
end

gemspec
