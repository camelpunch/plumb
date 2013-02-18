require 'httparty'
require_relative 'build_status'

module Plumb
  class WebReporter
    def initialize(url)
      @server = Class.new do include HTTParty end
      @server.base_uri url
    end

    def build_started(job)
      @server.put("/jobs/#{job.name}", body: job.to_json)
      @server.post("/jobs/#{job.name}/builds", body: body('building'))
    end

    def build_succeeded(job)
      @server.post("/jobs/#{job.name}/builds", body: body('success'))
    end

    def build_failed(job)
      @server.post("/jobs/#{job.name}/builds", body: body('failure'))
    end

    private

    def body(status)
      BuildStatus.new(status: status).to_json
    end
  end
end
