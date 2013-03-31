root = '../../../../'
require_relative "#{root}/spec/spec_helper"
require_relative "#{root}/lib/plumb/server/plumb_server"
require "rack/test"
require 'json'
require 'nokogiri'

module Plumb
  describe Server do
    include Rack::Test::Methods

    describe "creating a project (no ID supplied)" do
      it "responds with a 201 with a GETable location of the new project" do
        post '/projects', JSON.generate(name: 'Unit Tests')
        last_response.status.must_equal 201

        get last_response.headers['Location']
        json_response['name'].must_equal 'Unit Tests'
      end
    end

    describe "getting a project" do
      it "uses the JSON content type" do
        post '/projects', JSON.generate(name: 'Unit Tests')
        get last_response.headers['Location']
        last_response.content_type.must_include 'application/json'
      end
    end

    describe "adding a build to a project (client-generated ID)" do
      it "is reflected in the CCTray XML feed" do
        post '/projects', JSON.generate(name: 'Project with a build')
        new_project_url = last_response.headers['Location']

        generated_build_id = SecureRandom.uuid
        put "#{new_project_url}/builds/#{generated_build_id}",
          JSON.generate(status: "Success", completed_at: '2013-01-01 00:00')

        get '/dashboard/cctray.xml'
        last_response.status.must_equal 200

        project_xml = project('Project with a build')
        project_xml['lastBuildStatus'].must_equal 'Success'
        project_xml['activity'].must_equal 'Sleeping'
        project_xml['webUrl'].must_equal "http://example.org/dashboard/cctray.xml"
      end
    end

    describe "CCTray XML feed" do
      it "uses the XML content type" do
        get '/dashboard/cctray.xml'
        last_response.content_type.must_include 'text/xml'
      end
    end

    def app
      Plumb::Server
    end

    def json_response
      JSON.parse(last_response.body)
    end

    def feed
      Nokogiri::XML(last_response.body)
    end

    def project(name)
      feed.css("Projects>Project[name='#{name}']").first
    end
  end
end
