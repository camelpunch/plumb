require 'pathname'
require 'psych'
require_relative "../spec/server_spec_helper"

describe "plumb" do
  include Rack::Test::Methods
  include ServerSpecHelpers

  it "shows various statuses for a build's lifecycle in the CCTray feed" do
    in_temp_path do |path|
      IO.write path.join('plumb.yml'), Psych.dump(
        'server' => {
          'adapter' => ['rack', 'Plumb::Server'],
          'endpoint' => 'http://some.url/'
        },
        'projects' => {
          "happy_project" => {
            'name' => 'Happy Project',
            'script' => "> '#{path.join('created_file')}'",
            'repository_url' => 'git://foo.bar'
          }
        }
      )
      run_command_in_this_thread(path, 'plumb-configure')
      run_command_in_this_thread(path, 'plumb-run')
      project_activity('Happy Project').must_equal 'Building'

      # finish build
      get_dashboard
      build_id = last_build_label_for_project('Happy Project')
      put_build 'happy_project', build_id, status: 'Success'

      project_activity('Happy Project').must_equal 'Sleeping'
    end
  end

  def in_temp_path(&block)
    Dir.mktmpdir do |dir|
      block.call(Pathname(dir))
    end
  end

  def run_command_in_this_thread(working_dir, filename, *args)
    executable_path = File.expand_path("../../bin/#{filename}", __FILE__)
    old_working_dir = Dir.pwd
    Dir.chdir(working_dir)
    ARGV.clear
    args.each do |arg|
      ARGV << arg
    end
    load executable_path
    Dir.chdir old_working_dir
  end
end
