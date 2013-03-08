require 'minitest/autorun'
require 'minitest/reporters'
require 'webmock/minitest'

MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new
WebMock.allow_net_connect!

