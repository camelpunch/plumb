require 'pathname'
require 'psych'
require_relative "../spec/server_spec_helper"

describe "plumb" do
  include Rack::Test::Methods
  include ServerSpecHelpers

  it "shows various statuses for a build's lifecycle in the CCTray feed" do
    Dir.mktmpdir do |dir|
      config_path = "#{dir}/ci.yml"
      IO.write config_path, Psych.dump(
        'server' => {
          'adapter' => ['rack', 'Plumb::Server'],
          'endpoint' => 'http://some.url/'
        },
        'projects' => {
          "happy_project" => {
            'name' => 'Happy Project',
            'script' => "> '#{dir}/created_file'",
            'repository_url' => 'git://foo.bar'
          }
        }
      )
      run_command_in_this_thread('plumb-configure', config_path)

      # start build
      put_build 'happy_project', 'some-build-id', status: 'Building'
      project_activity('Happy Project').must_equal 'Building'

      # finish build
      get_dashboard
      build_id = last_build_label_for_project('Happy Project')
      put_build 'happy_project', build_id, status: 'Success'

      project_activity('Happy Project').must_equal 'Sleeping'
    end
  end

  def run_command_in_this_thread(filename, *args)
    ARGV.clear
    args.each do |arg|
      ARGV << arg
    end
    load File.expand_path("../../bin/#{filename}", __FILE__)
  end
end
