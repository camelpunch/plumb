module ServerSpecHelpers
  def put_project(id, attributes)
    put "/projects/#{id}", json(attributes)
  end

  def put_build(project_id, build_id, attributes)
    put "/projects/#{project_id}/builds/#{build_id}", json(attributes)
  end

  def get_dashboard
    get '/cc.xml'
  end

  def json(data)
    JSON.generate data
  end

  def json_response
    JSON.parse(last_response.body)
  end

  def feed
    Nokogiri::XML(last_response.body)
  end

  def project_activity(name)
    get_dashboard
    project_xml = feed.css("Projects>Project[name='#{name}']").first
    project_xml['activity']
  end

  def app
    Plumb::Server
  end
end
