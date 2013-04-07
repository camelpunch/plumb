require_relative '../spec_helper'
require_relative '../../app/models/config'

module Plumb
  SomeServer = Class.new

  describe Config do
    let(:config) {
      Config.new(
        'server' => {
          'endpoint' => 'http://some.endpoint',
          'adapter' => ['rack', 'Plumb::SomeServer'],
        },
        'projects' => {
          "happy_project" => {
            'name' => 'Happy Project',
            'script' => 'rake',
            'repository_url' => 'git://foo.bar'
          }
        }
      )
    }

    it "has an endpoint" do
      config.endpoint.must_equal 'http://some.endpoint'
    end

    it "has a faraday adapter array" do
      config.adapter.must_equal [:rack, Plumb::SomeServer]
    end

    it "instantiates an array of Projects from the config" do
      config.projects.must_equal [
        Project.new(id: 'happy_project',
                    name: 'Happy Project',
                    script: 'rake',
                    repository_url: 'git://foo.bar')
      ]
    end
  end
end
