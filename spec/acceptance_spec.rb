require_relative "../spec/spec_helper"
require_relative "../lib/plumb/server/plumb_server"
require "rack/test"
require 'json'
require 'nokogiri'

describe "plumb" do
  include Rack::Test::Methods
  include ServerSpecHelpers

  it "shows various statuses for a build's lifecycle in the CCTray feed" do
    project_id = SecureRandom.uuid
    build_id = SecureRandom.uuid

    put_project project_id, name: 'Happy Build'
    put_build project_id, build_id, status: 'Building'
    project_activity('Happy Build').must_equal 'Building'

    put_build project_id, build_id, status: 'Success'
    project_activity('Happy Build').must_equal 'Sleeping'
  end
end
