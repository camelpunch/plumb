require 'sinatra/base'
require_relative '../../../app/models/project'

module Plumb
  class Server < Sinatra::Base
    configure do
      set :raise_errors, true
      set :show_exceptions, false

      set :views, File.join(root, '../../../app/views')
    end

    get '/cc.xml' do
      content_type 'text/xml'
      erb :cctray, locals: {
        projects: Project.all,
        web_url: request.url
      }
    end

    put '/projects/:id' do
      content_type 'application/json'
      attributes = JSON.parse(request.body.read).merge(id: params[:id])
      existing = Project[params[:id]]
      existing ? existing.update(attributes)
               : Project.create(attributes)
      status 200
    end

    get '/projects/:id' do
      content_type 'application/json'
      Project[params[:id]].to_json
    end

    put '/projects/:project_id/builds/:id' do
      project = Project[params[:project_id]]
      existing_build = project.builds_dataset.first(id: params[:id])

      if existing_build
        existing_build.update(JSON.parse(request.body.read))
      else
        begin
          project.add_build(
            JSON.parse(request.body.read).merge(id: params[:id])
          )
        rescue Sequel::ConstraintViolation
          status 409
        end
      end
      '{}'
    end
  end
end
