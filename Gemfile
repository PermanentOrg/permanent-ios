source "https://rubygems.org"

gem "fastlane"
gem 'cocoapods', '~> 1.16.2'
gem 'xcodeproj', '~> 1.27.0'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
