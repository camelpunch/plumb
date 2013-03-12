module Plumb
  class QueueLogger
    def initialize(path)
      @path = path
    end

    def enqueued(item)
      write "enqueued #{item}"
    end

    def popped(item)
      write "popped   #{item}"
    end

    private

    attr_reader :path

    def write(text)
      File.open(path, 'a') do |file|
        file.puts text
      end
    end
  end
end
