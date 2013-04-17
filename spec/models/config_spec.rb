require_relative '../spec_helper'
require_relative '../../app/models/config'

module Plumb
  class TestConfig < MiniTest::Unit::TestCase
    def test_returns_projects_from_config
      config = Config.new(
        'projects' => {
          "happy_project" => {
            'name' => 'Happy Project',
            'script' => 'rake',
            'repository_url' => 'git://foo.bar'
          },
          "unhappy_project" => {
            'name' => 'Unhappy Project',
            'script' => 'rake',
            'repository_url' => 'git://foo.bar'
          }
        }
      )

      expected_project1 =
        Project.new(id: 'happy_project',
                    name: 'Happy Project',
                    script: 'rake',
                    repository_url: 'git://foo.bar')
      expected_project2 =
        Project.new(id: 'unhappy_project',
                    name: 'Unhappy Project',
                    script: 'rake',
                    repository_url: 'git://foo.bar')

      config.projects.to_a.
        must_equal [ expected_project1, expected_project2 ]

      config.projects.first.must_equal expected_project1

      config.projects.find_by_name('Happy Project').
        must_equal expected_project1
    end

    def test_parses_rack_adapter_faraday_settings
      config = Config.new(
        'server' => {
          'endpoint' => 'http://some.endpoint',
          'adapter' => ['rack', 'Plumb::Server'],
      })
      config.endpoint.must_equal 'http://some.endpoint'
      config.adapter.must_equal [:rack, Plumb::Server]
    end

    def test_parses_net_http_faraday_settings
      config = Config.new(
        'server' => {
          'endpoint' => 'http://some.endpoint',
          'adapter' => 'net_http',
        }
      )

      config.endpoint.must_equal 'http://some.endpoint'
      config.adapter.must_equal [:net_http]
    end
  end
end
