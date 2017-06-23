#ENV["RAILS_ENV"] = "test"

if ENV["RAILS_ENV"] == 'production' then
  puts 'You should not run tests on production'
  exit
end
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rake::Task["db:test:prepare"].clear rescue nil

namespace :db do
  namespace :test do
    task :prepare do
    end
  end
end


class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

  # Add more helper methods to be used by all tests here...
  attr_accessor :context

  alias :assert_with_msg :assert
  def assert val, msg=''
    desc = @context.join("\n")+"\n\n" rescue "\n"
    desc += "\n\nTest failing "
    desc += "at "+caller.join("\n")+"\n" rescue "\n"
    desc += msg.to_s + "\n" rescue "\n"
    assert_with_msg val, desc
  end
end
