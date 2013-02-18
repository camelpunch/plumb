require 'resque'
require_relative 'message'

module Plumb
  class ResqueQueue
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def <<(item)
      Resque::Job.create(@name, 'Plumb::ResqueQueue', [item])
    end

    def pop
      job = Resque.pop(@name)
      return nil unless job
      Plumb::Message.new(convert(job))
    end

    def destroy
      Resque.remove_queue(@name)
    end

    private

    def convert(job)
      job && JSON.generate(job['args'].first.first)
    end
  end
end
