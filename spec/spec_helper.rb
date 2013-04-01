require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/hell'
require 'securerandom'

MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

require_relative 'test_db'
