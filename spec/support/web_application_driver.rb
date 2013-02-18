require 'nokogiri'
require 'httparty'
require_relative '../../web/server'

module SpecSupport
  class WebApplicationDriver
    class Server
      include HTTParty
      def self.port
        6789
      end
      base_uri "localhost:#{port}"
    end

    def initialize(chatty)
      @chatty = chatty
    end

    def start
      @pid = Process.spawn("rackup -E test -I web -r server -p #{Server.port} web/config.ru",
                           :out => '/dev/null',
                           :err => '/dev/null')
      probe_until('server up') { server_is_up? }
      self
    end

    def stop
      Process.kill('KILL', @pid) if @pid
    rescue Errno::ESRCH
    ensure
      self
    end

    def with_no_data
      Server.delete("/jobs/all")
      self
    end

    def shows_green_build_xml_for(project_name)
      probe_until("sleeping build for #{project_name} available in feed") {
        project(project_name)['activity'] == 'Sleeping'
      }
      project(project_name)['lastBuildStatus'].must_equal 'Success', feed
    end

    def shows_red_build_xml_for(project_name)
      probe_until("sleeping build for #{project_name} available in feed") {
        project(project_name)['activity'] == 'Sleeping'
      }
      project(project_name)['lastBuildStatus'].must_equal 'Failure', feed
    end

    def shows_build_in_progress_xml_for(project_name)
      probe_until('build in progress available in feed') { project(project_name) }
      project(project_name)['activity'].must_equal 'Building'
    end

    private

    def server_is_up?
      Server.get("/dashboard/cctray.xml")
      true
    rescue SystemCallError
      false
    end

    def project(name)
      feed.css("Projects>Project[name='#{name}']").first or raise cant_find_name(name)
    end

    def feed
      response = Server.get("/dashboard/cctray.xml")
      Nokogiri::XML(response.body)
    end

    def humanize_value(value)
      value || "[#{value.class}]"
    end

    def probe_until(description, &block)
      log "----- Probe until #{description}"
      tries = 0
      value = nil

      value_truthy = -> {
        begin
          block.call
        rescue Exception => e
          err "----- Exception: #{e.message}"
          false
        end
      }

      until value_truthy.call || tries == 10 do
        log "----- Got value: #{humanize_value(value)}"
        tries += 1
        sleep 0.5
      end

      message =
        "-- Probe '#{description}' reached its limit\n\n" +
        "-- Last value: #{humanize_value(value)}\n\n"

      if tries == 10
        err message
      else
        log "-- #{description}!"
      end
    end

    def cant_find_name(name)
      if sinatra_error
        StandardError.new("Corrupted feed. Did you restart the server?\n\n" +
                          "#{sinatra_error[0]}")
      else
        StandardError.new("Can't find '#{name}' in #{feed}")
      end
    end

    def sinatra_error
      @sinatra_error ||= feed.text.match(/^        [A-Za-z]+ at \/dashboard.*BACKTRACE/m)
    end

    def log(text)
      puts text if @chatty
    end

    def err(text)
      $stderr.puts text if @chatty
    end
  end
end
