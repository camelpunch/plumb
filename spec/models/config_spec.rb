require_relative '../spec_helper'
require_relative '../../app/models/config'

module Plumb
  describe Config do
    let(:config) {
      Config.new(
        'server' => {
          'endpoint' => 'http://some.endpoint',
          'adapter' => ['rack', 'Plumb::Server'],
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

    it "instantiates an array of Projects from the config" do
      config.projects.must_equal [
        Storage::Project.new(id: 'happy_project',
                             name: 'Happy Project',
                             script: 'rake',
                             repository_url: 'git://foo.bar')
      ]
    end

    describe "for the rack adapter" do
      it "has an endpoint" do
        config.endpoint.must_equal 'http://some.endpoint'
      end

      it "has a faraday adapter array" do
        config.adapter.must_equal [:rack, Plumb::Server]
      end
    end

    describe "for the net_http adapter" do
      let(:config) {
        Config.new(
          'server' => {
            'endpoint' => 'http://some.endpoint',
            'adapter' => 'net_http',
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
        config.adapter.must_equal [:net_http]
      end
    end
  end
end
