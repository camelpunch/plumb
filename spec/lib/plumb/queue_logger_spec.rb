require_relative '../../spec_helper'
require_relative '../../../lib/plumb/queue_logger'
require 'tempfile'

module Plumb
  describe QueueLogger do
    it "logs when something is enqueued" do
      file = Tempfile.new('enqueued spec')
      logger = QueueLogger.new(file.path)
      logger.enqueued('something')
      File.read(file).must_equal "enqueued something\n"
    end

    it "logs when something is popped" do
      file = Tempfile.new('popped spec')
      logger = QueueLogger.new(file.path)
      logger.popped('something')
      File.read(file).must_equal "popped   something\n"
    end
  end
end
