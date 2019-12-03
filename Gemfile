# frozen_string_literal: true

source 'https://rubygems.org'
ruby "2.6.5"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'fastlane'
gem 'xcpretty'
# gem 'xcov', '~>1.5.0'
gem 'ejson'
gem 'dotenv'
gem 'unf_ext', '~>0.0.7.5'
gem 'cocoapods', '~>1.7.0'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
