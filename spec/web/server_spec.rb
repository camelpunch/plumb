require_relative '../spec_helper'
require 'json'
require 'rack/test'
require 'nokogiri'

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
      get('/jobs/unit-tests')
      last_response.content_type.must_include 'application/json'
    end

    it "responds with the requested job" do
      put('/jobs/unit-tests',
          Plumb::Job.new(name: 'unit-tests', ready: true).to_json)
      get('/jobs/unit-tests')
      JSON.parse(last_response.body)['name'].must_equal 'unit-tests'
      JSON.parse(last_response.body)['ready'].must_equal true
    end
  end

  describe "feed" do
    it "is empty when no builds have been stored" do
      delete_all_jobs
      get '/dashboard/cctray.xml'
      feed.css("Projects>Project").must_be_empty
    end

    it "uses the XML content type" do
      get '/dashboard/cctray.xml'
      last_response.content_type.must_include 'text/xml'
    end

    it "shows a successful build" do
      delete_all_jobs

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

    it "shows a failed build" do
      delete_all_jobs

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
      delete_all_jobs

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
