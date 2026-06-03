require "fileutils"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'spree/testing_support/extension_rake'

RSpec::Core::RakeTask.new(:spec)

task :default do
  if Dir["spec/dummy"].empty?
    Rake::Task[:test_app].invoke
    Dir.chdir("../../")
  end
  Rake::Task[:spec].invoke
end

desc 'Generates a dummy app for testing'
task :test_app do
  ENV['LIB_NAME'] = 'super_good/solidus_taxjar'

  begin
    Rake::Task['extension:test_app'].invoke
  rescue => error
    # Rails 8: Rails no longer generates a sprockets manifest, but Solidus still
    # uses sprockets, so sprockets-rails 3.5 aborts boot with a
    # Sprockets::Railtie::ManifestNeededError before the dummy app's database is
    # ever set up. Upstream fixed this by having the generators write
    # app/assets/config/manifest.js (mirrors solidusio/solidus#6121, #6122; see
    # also #6327 / #3379). The Solidus 2.11 generators predate that, so seed the
    # manifest here and re-run the database setup that common:test_app aborted.
    # common:test_app shells out via `sh`, so the boot failure surfaces as a
    # generic "Command failed" RuntimeError; recover only when the dummy app
    # exists but is missing the manifest that triggers this exact abort.
    manifest_path = File.expand_path("spec/dummy/app/assets/config/manifest.js", __dir__)
    dummy_generated = File.exist?(File.expand_path("spec/dummy/config/environment.rb", __dir__))
    raise unless dummy_generated && !File.exist?(manifest_path)

    FileUtils.mkdir_p(File.dirname(manifest_path))
    File.write(manifest_path, <<~MANIFEST)
      //= link_tree ../images
      //= link_directory ../javascripts .js
      //= link_directory ../stylesheets .css
    MANIFEST

    Dir.chdir(File.expand_path("spec/dummy", __dir__)) do
      sh "bin/rails railties:install:migrations RAILS_ENV=test"
      sh "bin/rails db:environment:set RAILS_ENV=test"
      sh "bin/rails db:drop db:create db:migrate VERBOSE=false RAILS_ENV=test"
    end
  end
end
