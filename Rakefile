#require 'bundler/gem_tasks'
require 'bundler/gem_helper'
require 'rspec/core/rake_task'
require 'jars/installer'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Install JAR dependencies"
task :install_jars do
  Jars::Installer.vendor_jars!
end

namespace :new_saxon do
  Bundler::GemHelper.install_tasks(name: 'saxon-rb')
end
namespace :old_saxon do
  Bundler::GemHelper.install_tasks(name: 'saxon')
end