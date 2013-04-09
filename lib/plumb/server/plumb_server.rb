require 'sinatra/base'
require_relative '../../../app/models/storage/project'
require_relative '../../../app/models/database_project_mapper'

module Plumb
  class Server < Sinatra::Base
    Projects = DatabaseProjectMapper.new

    configure do
      set :raise_errors, true
      set :show_exceptions, false

      set :views, File.join(root, '../../../app/views')
    end

    get '/cc.xml' do
      content_type 'text/xml'
      erb :cctray, locals: {
        projects: Projects.all,
        web_url: request.url
      }
    end

    put '/projects/:id' do
      content_type 'application/json'
      attributes = JSON.parse(request.body.read).merge(id: params[:id])

      begin
        Projects.update(params[:id], attributes)
      rescue DatabaseProjectMapper::ProjectNotFound
        Projects.insert(attributes)
      end

      status 200
    end

    get '/projects/:id' do
      content_type 'application/json'
      Projects.get(params[:id]).to_json
    end

    put '/projects/:project_id/builds/:id' do
      content_type 'application/json'

      begin
        Projects.update(
          params[:project_id],
          builds: [ JSON.parse(request.body.read).merge(id: params[:id]) ]
        )
      rescue DatabaseProjectMapper::Conflict
        status 409
      end

      '{}'
    end
  end
end
