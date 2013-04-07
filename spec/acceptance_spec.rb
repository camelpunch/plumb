require 'pathname'
require 'psych'
require_relative "../spec/server_spec_helper"

describe "plumb" do
  include Rack::Test::Methods
  include ServerSpecHelpers

  it "shows various statuses for a build's lifecycle in the CCTray feed" do
    Dir.mktmpdir do |dir|
      bin_path = Pathname(File.expand_path('../../bin', __FILE__))
      config_path = Pathname(dir)
      IO.write config_path.join('ci.yml'), Psych.dump(
        'server' => {
          'adapter' => ['rack', 'Plumb::Server'],
          'endpoint' => 'http://some.url/'
        },
        'projects' => {
          "happy_project" => {
            'name' => 'Happy Project',
            'script' => 'rake',
            'repository_url' => 'git://foo.bar'
          }
        }
      )
      run_command_in_this_thread(
        bin_path.join('plumb-configure'),
        config_path.join('ci.yml')
      )
    end

    put_build 'happy_project', 'some-build-id', status: 'Building'
    project_activity('Happy Project').must_equal 'Building'

    get_dashboard
    build_id = last_build_label_for_project('Happy Project')
    put_build 'happy_project', build_id, status: 'Success'

    project_activity('Happy Project').must_equal 'Sleeping'
  end

  def run_command_in_this_thread(path, first_arg)
    ARGV[0] = first_arg
    load path
  end
end
