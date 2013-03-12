require 'pathname'
require 'securerandom'
require 'json'
require_relative '../spec_helper'
require_relative '../support'
require_relative '../../lib/plumb'

describe "CI end-end" do
  let(:queue_config) { SpecSupport::QueueConfig.new(queue_driver, web_app.url) }
  let(:queue_driver) { Plumb::ResqueQueue }
  let(:web_app) { SpecSupport::WebApplicationDriver.new }
  let(:pipeline_processor) { SpecSupport::PipelineProcessorDriver.new(queue_config.path) }
  let(:repo) { SpecSupport::GitRepository.new }
  let(:queue_names) { [:immediate_queue, :waiting_queue] }
  let(:queue_runners) {
    [
      SpecSupport::QueueRunnerDriver.new('pipeline-waiting-queue-runner', queue_config.path),
      SpecSupport::QueueRunnerDriver.new('pipeline-immediate-queue-runner', queue_config.path)
    ]
  }

  before do
    queue_config.write
  end

  after do
    repo.destroy
    web_app.stop
    queue_runners.each(&:stop)
    queue_names.each do |name|
      queue_driver.new(queue_config[name]).destroy
    end
  end

  it "executes parallel builds but cancels children if a parent build fails" do
    web_app.start.with_no_data
    repo.create

    child_side_effect_file = Tempfile.new('child side effect')
    aunty_side_effect_file = Tempfile.new('aunty side effect')
    repo.create_commit(
      parent: 'exit 1',
      aunty: %Q( `echo 'aunty side effect' > "#{aunty_side_effect_file.path}"` ),
      child: %Q( `echo 'child side effect' > "#{child_side_effect_file.path}"` )
    )

    queue_runners.each(&:start)

    pipeline_processor.run(
      order: [
        [
          { name: 'parent', script: 'rake parent', repository_url: repo.url },
          { name: 'aunty', script: 'rake aunty', repository_url: repo.url },
        ],
        [ { name: 'child', script: 'rake child', repository_url: repo.url } ]
      ]
    )

    File.read(child_side_effect_file).must_be :empty?
    File.read(aunty_side_effect_file).must_equal 'aunty side effect'
    web_app.shows_red_build_xml_for('parent')
    web_app.shows_green_build_xml_for('aunty')
    web_app.shows_green_build_xml_for('child')
  end

  it "shows a single green build in the feed" do
    web_app.start.with_no_data
    repo.create
    repo.create_commit(units: 'exit 0')
    queue_runners.each(&:start)

    pipeline_processor.run(
      order: [
        [
          {
            name: 'unit-tests',
            repository_url: repo.url,
            script: 'rake units'
          }
        ]
      ]
    )

    web_app.shows_green_build_xml_for('unit-tests')
  end

  it "shows builds in progress in the feed" do
    skip
    web_app.start.with_no_data
    repo.create
    repo.create_commit(long_run: 'sleep 10')
    queue_runners.each(&:start)
    pipeline_processor.run(
      order: [
        [
          {
            name: 'unit-tests',
            repository_url: repo.url,
            script: 'rake long_run'
          }
        ]
      ]
    )
    web_app.shows_build_in_progress_xml_for('unit-tests')
  end
end
