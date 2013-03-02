require 'json'

module SpecSupport
  class PipelineProcessorDriver
    attr_reader :cmd_path, :config_path

    def initialize(config_path)
      @cmd_path = File.expand_path('../../../bin/plumb-pipeline-processor', __FILE__)
      @config_path = config_path
    end

    def run(pipeline)
      cmd = "echo '#{JSON.generate(pipeline)}' | #{cmd_path} #{config_path}"
      system cmd or raise "command failed"
    end
  end
end
