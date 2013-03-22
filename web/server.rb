#!/usr/bin/env ruby
require 'sinatra/base'
require 'sequel'
require_relative '../lib/plumb/build_status'
require_relative '../lib/plumb/job'
require_relative '../lib/plumb/filesystem_storage'
require_relative '../lib/plumb/views/cctray_project'

DB = Sequel.sqlite
require_relative 'models/job'
require_relative 'models/build'

module Plumb
  class Server < Sinatra::Base
    get '/dashboard/cctray.xml' do
      log "GET to CCTray XML"
      content_type 'text/xml'
      puts "Grabbing all #{Storage::Job.count} jobs"
      puts "Last Job: #{Storage::Job.last.to_json}"
      erb :cctray, locals: {
        projects: Storage::Job.all.map {|job| Plumb::CCTrayProject.new(job)},
        web_url: request.url
      }
    end

    get "/jobs/:job_name" do
      log "GET #{params[:job_name]}"
      content_type 'application/json'
      job = Storage::Job.first(name: params[:job_name])
      raise Sinatra::NotFound unless job
      job.to_json
    end

    put "/jobs/:job_name" do
      log "Storing job #{params}"
      attributes = Plumb::Job.parse(request.body.read).to_h
      job = Storage::Job.new(attributes)
      job.save
      '{}'
    end

    delete "/jobs/all" do
      log "Deleting all jobs"
      Storage::Job.all.each(&:delete)
      '{}'
    end

    post "/jobs/:job_name/builds" do
      log "Storing build #{params}"
      job = Storage::Job.first(name: params[:job_name])
      raise Sinatra::NotFound unless job
      status = Plumb::BuildStatus.parse(request.body.read)
      job.build_started(status)
      puts "Count on POST: #{Storage::Job.count}"
      puts "Last Job on POST: #{Storage::Job.last.to_json}"
      puts "Last build on POST: #{Storage::Build.last.status}"
      '{}'
    end

    def log(text)
      File.open(File.expand_path('../web.log', __FILE__), 'a') do |file|
        file.puts "PORT #{request.port} :: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{text}"
      end
    end

    run! if app_file == $0
  end
end
