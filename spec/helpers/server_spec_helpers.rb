module ServerSpecHelpers
  IncompleteXML = Class.new(StandardError)

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

  def project_xml(name)
    get_dashboard
    feed.css("Projects>Project[name='#{name}']").first.tap do |project_xml|
      raise IncompleteXML, last_response.body unless project_xml
    end
  end

  def project_activity(name)
    project_xml(name)['activity']
  end

  def last_build_label_for_project(name)
    project_xml(name)['lastBuildLabel']
  end

  def app
    Plumb::Server
  end
end
