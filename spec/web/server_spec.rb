require_relative '../spec_helper'
require 'json'
require 'rack/test'
require 'nokogiri'
require 'sequel'

module Plumb
  module  Storage
    DB = Sequel.sqlite('web/test.db')
  end
end

ENV['RACK_ENV'] = 'test' # must be before server require
require_relative '../../web/server'

describe "web server" do
  include Rack::Test::Methods

  describe "creating a job" do
    it "returns 200 on success" do
      put('/jobs/unit-tests', Plumb::Job.new(name: 'unit-tests').to_json)
      last_response.status.must_equal 200
    end
  end

  describe "getting an individual job" do
    it "is in JSON format" do
      put('/jobs/jsony',
          Plumb::Job.new(name: 'jsony', ready: true).to_json)
      get('/jobs/jsony')
      last_response.content_type.must_include 'application/json'
    end

    it "responds with the requested job" do
      put('/jobs/unit-tests',
          Plumb::Job.new(name: 'unit-tests', ready: true).to_json)
      get('/jobs/unit-tests')
      last_json_response['name'].must_equal 'unit-tests'
      last_json_response['ready'].must_equal true
    end

    it "responds with 404 if it doesn't exist" do
      get('/jobs/foobypotato')
      last_response.status.must_equal 404
    end
  end

  describe "adding a successful build" do
    describe "to a job that doesn't exist" do
      it "responds with 404" do
        post('/jobs/sdfgaag/builds', Plumb::BuildStatus.new(status: 'success').to_json)
        last_response.status.must_equal 404
      end
    end

    describe "to a job without siblings but with ancestors" do
      it "readies child jobs" do
        skip
        parent = Plumb::Job.new(
          name: 'parent',
          ready: true,
          children: ['child']
        )
        child = Plumb::Job.new(
          name: 'child',
          ready: false
        )
        put('/jobs/parent', parent.to_json)
        put('/jobs/child', child.to_json)
        post('/jobs/parent/builds',
             Plumb::BuildStatus.new(status: 'success').to_json)
        get('/jobs/child')
        last_json_response['ready'].must_equal true
      end

      it "doesn't ready grandparent jobs"
    end
  end

  describe "feed" do
    before do
      delete_all_jobs
    end

    it "is empty when no builds have been stored" do
      get '/dashboard/cctray.xml'
      feed.css("Projects>Project").must_be_empty
    end

    it "uses the XML content type" do
      get '/dashboard/cctray.xml'
      last_response.content_type.must_include 'text/xml'
    end

    it "shows a successful build" do
      put '/jobs/unit-tests', Plumb::Job.new(name: 'unit-tests').to_json
      post '/jobs/unit-tests/builds', Plumb::BuildStatus.new(status: 'success').to_json
      get '/dashboard/cctray.xml'

      assert project('unit-tests'),
        "The stored Job did not appear as a Project in the feed:\n\n#{feed.to_s}"

      project('unit-tests')['lastBuildStatus'].must_equal 'Success', project('unit-tests')
      project('unit-tests')['activity'].must_equal 'Sleeping'
      project('unit-tests')['webUrl'].
        must_equal "http://example.org/dashboard/cctray.xml"
    end

    # no API for updating builds, and no support in app either
    it "shows a failed build" do
      put '/jobs/My-Project', Plumb::Job.new(name: 'My-Project').to_json
      post '/jobs/My-Project/builds', Plumb::BuildStatus.new(status: 'failure').to_json

      get '/dashboard/cctray.xml'

      assert project('My-Project'),
        "The stored Job did not appear as a Project in the feed:\n\n#{feed.to_s}"

      project('My-Project')['lastBuildStatus'].must_equal 'Failure'
      project('My-Project')['activity'].must_equal 'Sleeping'
      project('My-Project')['webUrl'].
        must_equal "http://example.org/dashboard/cctray.xml"
    end

    it "shows a build in progress" do
      put '/jobs/progress-project', Plumb::Job.new(name: 'progress-project').to_json
      post '/jobs/progress-project/builds', Plumb::BuildStatus.new(status: 'building').to_json

      get '/dashboard/cctray.xml'

      assert project('progress-project'),
        "The stored Job did not appear as a Project in the feed:\n\n#{feed.to_s}"

      project('progress-project')['activity'].must_equal 'Building'
      project('progress-project')['lastBuildStatus'].must_be :empty?
      project('progress-project')['webUrl'].
        must_equal "http://example.org/dashboard/cctray.xml"
    end
  end

  def delete_all_jobs
    delete "/jobs/all"
    assert last_response.ok?, "bad DELETE response"
  end

  def last_json_response
    JSON.parse(last_response.body)
  rescue StandardError => e
    raise "body could not be parsed as JSON: #{last_response.body}"
  end

  def project(name)
    feed.css("Projects>Project[name='#{name}']").first
  end

  def feed
    Nokogiri::XML(last_response.body)
  end

  def app
    Plumb::Server
  end
end
