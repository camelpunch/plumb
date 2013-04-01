require 'sinatra/base'
require_relative '../../../app/models/project'

module Plumb
  class Server < Sinatra::Base
    configure do
      set :raise_errors, true
      set :show_exceptions, false

      set :views, File.join(root, '../../../app/views')
    end

    get '/dashboard/cctray.xml' do
      content_type 'text/xml'
      erb :cctray, locals: {
        projects: Project.all,
        web_url: request.url
      }
    end

    put '/projects/:id' do
      content_type 'application/json'
      project = Project.create(
        JSON.parse(request.body.read).merge(id: params[:id])
      )
      status 200
    end

    get '/projects/:id' do
      content_type 'application/json'
      Project[params[:id]].to_json
    end

    put '/projects/:project_id/builds/:id' do
      Project[params[:project_id]].add_build(
        JSON.parse(request.body.read).merge(id: params[:id])
      )
    end
  end
end
