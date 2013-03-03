require 'pathname'
require 'securerandom'
require 'json'
require_relative '../spec_helper'
require_relative '../support'
require_relative '../../lib/plumb'

describe "CI end-end" do
  self.parallelize_me!

  let(:queue_config) { SpecSupport::QueueConfig.new(queue_driver, web_app.url) }
  let(:queue_driver) { Plumb::ResqueQueue }
  let(:web_app) { SpecSupport::WebApplicationDriver.new }
  let(:pipeline_processor) { SpecSupport::PipelineProcessorDriver.new(queue_config.path) }
  let(:repository) { SpecSupport::GitRepository.new }
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
    repository.destroy
    web_app.stop
    queue_runners.each(&:stop)
    queue_names.each do |name|
      queue_driver.new(queue_config[name]).destroy
    end
  end

  it "shows a single green build in the feed" do
    web_app.start.with_no_data

    repository.create
    repository.create_good_commit
    queue_runners.each(&:start)

    pipeline_processor.run(
      order: [
        [
          {
            name: 'unit-tests',
            repository_url: repository.url,
            script: 'rake'
          }
        ]
      ]
    )

    web_app.shows_green_build_xml_for('unit-tests')
  end

  it "shows a single red build in the feed" do
    web_app.start.with_no_data

    repository.create
    repository.create_bad_commit
    queue_runners.each(&:start)
    pipeline_processor.run(
      order: [
        [
          {
            name: 'unit-tests',
            repository_url: repository.url,
            script: 'rake'
          }
        ]
      ]
    )
    web_app.shows_red_build_xml_for('unit-tests')
  end

  it "shows builds in progress in the feed" do
    web_app.start.with_no_data

    repository.create
    repository.create_commit_with_long_running_default_rake_task
    queue_runners.each(&:start)
    pipeline_processor.run(
      order: [
        [
          {
            name: 'unit-tests',
            repository_url: repository.url,
            script: 'rake'
          }
        ]
      ]
    )
    web_app.shows_build_in_progress_xml_for('unit-tests')
  end
end
