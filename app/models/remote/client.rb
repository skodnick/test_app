require 'typhoeus/adapters/faraday'

module Remote
  class Client
    attr_reader :connection

    def initialize
      @connection = Faraday.new do |f|
        f.adapter :typhoeus
        f.use Faraday::Response::RaiseError
        f.options.timeout = timeout
        f.options.open_timeout = open_timeout
      end
    end

    def self.get(url, opts = {})
      new.get(url, opts)
    end

    def get(url, opts= {})
      send_request(url, :get, opts)
    end

    private

    def send_request(url, method, opts)
      begin
        response = nil
        response_time = benchmark { response = connection.send(method, url, opts[:query]) }

        { response: Remote::Response.new(response), response_time: response_time }
      rescue Faraday::Error::TimeoutError, Timeout::Error
        { error: 'Request timeout' }
      rescue Faraday::Error => e
        error_message = e.message

        error_description = try_to_parse_erroneous_response(e.response)
        { error: "#{error_message} (#{error_description})" }
      rescue Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError => e
        { error: e.message }
      end
    end

    def benchmark(&block)
      time = Benchmark.measure(&block)
      (time.real * 1000).round(2)
    end

    def timeout
      SponsorPaySettings.timeout || 2
    end

    def open_timeout
      SponsorPaySettings.open_timeout || 2
    end

    # Ideally any response even with 400 status should contain json in its body,
    # but unexpected responses like '502 Bad Gateway' probably will have plain text in body.
    # So we try to parse json body and in cases of plain text error message contains exception's message.
    def try_to_parse_erroneous_response(response)
      if response[:body].present?
        parsed = Oj.load(response[:body], mode: :compat)
        if parsed.is_a?(Hash)
          parsed.values.join(', ')
        else
          parsed
        end
      end
    rescue Oj::ParseError
      nil
    end
  end
end
