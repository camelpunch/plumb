require_relative '../spec_helper'
require 'pathname'
require 'securerandom'
require 'json'
require_relative '../support'
require_relative '../../lib/plumb'

describe "CI end-end" do
  self.parallelize_me!

  let(:uuid) { SecureRandom.uuid }
  let(:queue_config_path) {
    File.expand_path("../../support/queue_config-#{uuid}.json", __FILE__)
  }
  let(:queue_config) { JSON.parse(File.read(queue_config_path)) }
  let(:queue_driver) { Plumb::ResqueQueue }
  let(:web_app) { SpecSupport::WebApplicationDriver.new }
  let(:pipeline_processor) {
    SpecSupport::PipelineProcessorDriver.new(queue_config_path)
  }
  let(:waiting_queue_runner) {
    SpecSupport::QueueRunnerDriver.new(
      'pipeline-waiting-queue-runner',
      queue_config_path
    )
  }
  let(:immediate_queue_runner) {
    SpecSupport::QueueRunnerDriver.new(
      'pipeline-immediate-queue-runner',
      queue_config_path
    )
  }
  let(:repository) { SpecSupport::GitRepository.new }
  let(:queue_runners) { [waiting_queue_runner, immediate_queue_runner] }

  before do
    write_new_queue_config
  end

  after do
    repository.destroy
    web_app.stop
    queue_runners.each(&:stop)
    delete_queues
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

  def delete_queues
    queue_names.each do |name|
      queue_driver.new(queue_config[name]).destroy
    end
  rescue StandardError
  end

  def write_new_queue_config
    File.open(queue_config_path, 'w') do |file|
      file << JSON.generate(
        driver: queue_driver.name.split('::').last,
        immediate_queue: "pipeline-immediate-queue-#{uuid}",
        waiting_queue: "pipeline-waiting-queue-#{uuid}",
        build_status_endpoint: "http://localhost:#{web_app.port}"
      )
    end
  end

  def queue_names
    queue_config.keys.grep(/_queue$/)
  end
end
