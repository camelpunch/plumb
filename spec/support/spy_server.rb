require 'thread'
require 'webrick'

module SpecSupport
  class SpyServer
    class << self
      attr_accessor :queue
    end

    def initialize(port)
      @port = port
      SpyServer.queue = ::Queue.new
    end

    def record_put_requests_to(path)
      server.mount(@path, PutServlet)
    end

    def start
      Thread.new { server.start }.abort_on_exception = true
    end

    def last_request
      SpyServer.queue.pop(non_block = true)
    end

    private

    def server
      @server ||= WEBrick::HTTPServer.new(
        Port: @port,
        AccessLog: [],
        Logger: WEBrick::Log.new('/dev/null', 7)
      )
    end

    class PutServlet < WEBrick::HTTPServlet::AbstractServlet
      def do_PUT(request, _)
        SpyServer.queue << [request.request_method, request.body]
      end
    end
  end
end

