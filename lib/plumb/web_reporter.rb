require 'httparty'
require_relative 'build_status'

module Plumb
  class WebReporter
    def initialize(url)
      @url = url
    end

    def build_started(job)
      server.put("/jobs/#{job.to_param}", body: job.to_json)
      server.post("/jobs/#{job.to_param}/builds", body: body('building'))
    end

    def build_succeeded(job)
      server.post("/jobs/#{job.to_param}/builds", body: body('success'))
    end

    def build_failed(job)
      server.post("/jobs/#{job.to_param}/builds", body: body('failure'))
    end

    private

    attr_reader :url

    def server
      Class.new { include HTTParty }.tap do |server|
        server.base_uri url
      end
    end

    def body(status)
      BuildStatus.new(status: status).to_json
    end
  end
end
