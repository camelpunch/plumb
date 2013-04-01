require_relative "../../../../spec/spec_helper"
require_relative "../../../../lib/plumb/server/plumb_server"
require "rack/test"
require 'json'
require 'nokogiri'

module Plumb
  describe Server do
    include Rack::Test::Methods

    describe "putting a new project" do
      it "is reflected in the CCTray XML feed" do
        id = SecureRandom.uuid
        put "/projects/#{id}", json(name: 'My New Project')
        last_response.status.must_equal 200

        get '/dashboard/cctray.xml'
        project_xml = feed.css("Projects>Project[name='My New Project']").first
        project_xml['lastBuildStatus'].must_equal 'Unknown'
      end
    end

    describe "getting a project" do
      it "uses the JSON content type" do
        id = SecureRandom.uuid
        post "/projects/#{id}", json(name: 'Unit Tests')
        get "/projects/#{id}"
        last_response.content_type.must_include 'application/json'
      end
    end

    describe "putting a new build on a project" do
      it "is reflected in the CCTray XML feed" do
        id = SecureRandom.uuid
        build_id = SecureRandom.uuid

        put "/projects/#{id}", json(name: 'Project with a build')
        put "/projects/#{id}/builds/#{build_id}",
            json(status: "Success", completed_at: '2013-01-01 00:00')

        get '/dashboard/cctray.xml'
        project_xml = feed.css("Projects>Project[name='Project with a build']").first
        project_xml['lastBuildStatus'].must_equal 'Success'
        project_xml['activity'].must_equal 'Sleeping'
        project_xml['webUrl'].must_equal "http://example.org/dashboard/cctray.xml"
      end
    end

    describe "putting an existing build on a project" do
      it "is reflected in the CCTray XML feed" do
        id = SecureRandom.uuid
        build_id = SecureRandom.uuid

        put "/projects/#{id}", json(name: 'Existence')
        put "/projects/#{id}/builds/#{build_id}",
            json(status: "Building", started_at: '2013-01-01 00:00')
        put "/projects/#{id}/builds/#{build_id}",
            json(status: "Success", completed_at: '2013-01-02 00:00')
        get '/dashboard/cctray.xml'

        project_xml = feed.css("Projects>Project[name='Existence']").first
        project_xml['lastBuildStatus'].must_equal 'Success'
      end
    end

    describe "putting another project's build ID on a project" do
      it "409s" do
        id1 = SecureRandom.uuid
        id2 = SecureRandom.uuid
        build_id = SecureRandom.uuid

        put "/projects/#{id1}", json(name: 'Project1')
        put "/projects/#{id2}", json(name: 'Project2')
        put "/projects/#{id1}/builds/#{build_id}",
            json(status: "Building", started_at: '2013-01-01 00:00')
        put "/projects/#{id2}/builds/#{build_id}",
            json(status: "Success", completed_at: '2013-01-02 00:00')

        last_response.status.must_equal 409
      end

      it "doesn't update the existing build"
    end

    describe "getting the CCTray XML feed" do
      it "uses the XML content type" do
        get '/dashboard/cctray.xml'
        last_response.content_type.must_include 'text/xml'
      end

      it "always gives a 200" do
        get '/dashboard/cctray.xml'
        last_response.status.must_equal 200
      end
    end

    def app
      Plumb::Server
    end

    def json(data)
      JSON.generate data
    end

    def json_response
      JSON.parse(last_response.body)
    end

    def feed
      Nokogiri::XML(last_response.body)
    end
  end
end
