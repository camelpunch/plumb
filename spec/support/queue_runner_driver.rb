require_relative '../../lib/plumb/sqs_queue'

module SpecSupport
  class QueueRunnerDriver
    def initialize(queue_name, config_path)
      @queue_name = queue_name
      @cmd_path = File.expand_path(
        "../../../bin/plumb-#{queue_name}",
        __FILE__
      )
      @config_path = config_path
    end

    def start
      @pid = Process.spawn("#{@cmd_path} #{@config_path}",
                           :out => $stdout,
                           :err => $stdout)
    end

    def stop
      Process.kill('KILL', @pid) if @pid
    rescue Errno::ESRCH
    end
  end
end
