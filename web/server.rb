#!/usr/bin/env ruby
require 'sinatra/base'
require_relative '../lib/plumb/build_status'
require_relative '../lib/plumb/job'
require_relative '../lib/plumb/filesystem_job_storage'
require_relative '../lib/plumb/views/cctray_project'

module Plumb
  class Server < Sinatra::Base
    FEED_PATH = File.expand_path('../cc.xml', __FILE__)
    DATABASE_NAME = "db-#{ENV['RACK_ENV'] || 'production'}.json"
    JOBS = Plumb::FileSystemJobStorage.new(
      File.expand_path("../#{DATABASE_NAME}", __FILE__)
    )

    def log(text)
      File.open(File.expand_path('../web.log', __FILE__), 'a') do |file|
        file.puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{text}"
      end
    end

    def jobs_are_now
      "Jobs are now: #{JOBS.to_a}"
    end

    get '/dashboard/cctray.xml' do
      log "GET to CCTray XML"
      content_type 'text/xml'
      erb :cctray, locals: {
        projects: JOBS.map {|job| Plumb::CCTrayProject.new(job)},
        web_url: request.url
      }
    end

    put "/jobs/:job_name" do
      log "Storing job #{params}"
      JOBS << Plumb::Job.parse(request.body.read)
      log jobs_are_now
      '{}'
    end

    delete "/jobs/all" do
      log "Deleting all jobs"
      JOBS.clear
      log jobs_are_now
      '{}'
    end

    post "/jobs/:job_name/builds" do
      log "Storing build #{params}"
      build_status = Plumb::BuildStatus.parse(request.body.read)
      JOBS.update(params[:job_name]) do |job|
        job.with_build_status(build_status)
      end
      log jobs_are_now
      '{}'
    end

    run! if app_file == $0
  end
end
