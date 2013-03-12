require 'nokogiri'
require 'httparty'
require_relative '../../web/server'

module SpecSupport
  class WebApplicationDriver
    def self.next_available_environment
      @current_env ||= 0
      @current_env += 1
      "test#{@current_env}"
    end

    def self.next_available_port
      @current_port ||= 3000 # don't use common Rails port
      @current_port += 1
      @current_port
    end

    def initialize(logger = Logger.new)
      @logger = logger
      @server = Class.new { include HTTParty }
      @server.base_uri "localhost:#{port}"
    end

    def start
      @pid = Process.spawn(
        "rackup -E #{environment} -I web -r server -p #{port} web/config.ru",
        :out => '/dev/null',
        :err => '/dev/null'
      )
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
      @server.delete("/jobs/all")
      self
    end

    def url
      "http://localhost:#{port}"
    end

    def port
      @port ||= WebApplicationDriver.next_available_port
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

    def environment
      @environment ||= WebApplicationDriver.next_available_environment
    end

    def server_is_up?
      @server.get("/dashboard/cctray.xml")
      true
    rescue SystemCallError
      false
    end

    def project(name)
      feed.css("Projects>Project[name='#{name}']").first or raise cant_find_name(name)
    end

    def feed
      response = @server.get("/dashboard/cctray.xml")
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
        StandardError.new("Corrupted feed.\n\n" + "#{sinatra_error[0]}")
      else
        StandardError.new("Can't find '#{name}' in #{feed}")
      end
    end

    def sinatra_error
      @sinatra_error ||= feed.text.match(/^        [A-Za-z]+ at \/dashboard.*BACKTRACE/m)
    end

    def log(text)
      @logger.log text
    end

    def err(text)
      @logger.err text
    end
  end

  class NullLogger
    def log(text); end
    def err(text); end
  end

  class Logger
    def log(text); puts text; end
    def err(text); $stderr.puts text; end
  end
end
