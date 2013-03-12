class SpecSupport::QueueConfig
  def initialize(driver, url)
    @driver = driver
    @url = url
  end

  def write
    File.open(path, 'w') do |file|
      file << JSON.generate(
        driver: driver.name.split('::').last,
        immediate_queue: "pipeline-immediate-queue-#{uuid}",
        waiting_queue: "pipeline-waiting-queue-#{uuid}",
        build_status_endpoint: url
      )
    end
  end

  def path
    @path ||= File.expand_path("../../support/queue_config-#{uuid}.json", __FILE__)
  end

  def [](key)
    contents[key.to_s]
  end

  private

  attr_reader :url, :driver

  def contents
    @contents ||= JSON.parse(File.read(path))
  end

  def uuid
    @uuid ||= SecureRandom.uuid
  end
end
