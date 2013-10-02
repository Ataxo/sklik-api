require 'rubygems'
require 'bundler'
require 'fakeweb'

require 'simplecov'
SimpleCov.start 'test_frameworks' do
end

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'test/unit'
require 'turn'
require 'shoulda-context'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sklik-api'
require './test/fake_web'


#set test account for travis!
if ENV['TRAVIS'] == "yes"
  SklikApi::Access.set(
      :email => "test-travis@seznam.cz",
      :password => "passwordfortravis"
    )
  #use production (not sandbox)
  SklikApi.use_sandbox_for_test = false

  #disable logger
  SklikApi.logger = nil
else
  SklikApi.logger = Logger.new('log/sklik_api_test.log')
end

class Test::Unit::TestCase
end
