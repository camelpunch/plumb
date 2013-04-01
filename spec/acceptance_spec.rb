require_relative "../spec/spec_helper"
require_relative "../lib/plumb/server/plumb_server"
require "rack/test"
require 'json'
require 'nokogiri'

describe "plumb" do
  include Rack::Test::Methods

  it "shows various statuses for a build's lifecycle in the CCTray feed" do
    project_id = SecureRandom.uuid
    build_id = SecureRandom.uuid

    put "/projects/#{project_id}", json(name: 'Happy Build')
    put "/projects/#{project_id}/builds/#{build_id}", json(status: "Building")

    project_activity('Happy Build').must_equal 'Building'

    put "/projects/#{project_id}/builds/#{build_id}", json(status: "Success")

    project_activity('Happy Build').must_equal 'Sleeping'
  end

  def project_activity(name)
    get "/dashboard/cctray.xml"
    project_xml = feed.css("Projects>Project[name='#{name}']").first
    project_xml['activity']
  end

  def json(data)
    JSON.generate data
  end

  def feed
    Nokogiri::XML(last_response.body)
  end

  def app
    Plumb::Server
  end
end
