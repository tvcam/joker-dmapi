require "net/http"
require "addressable/uri"
require "joker-dmapi/contact"
require "joker-dmapi/domain"

module JokerDMAPI
  VERSION = '0.0.1'

  class Client
    URI = 'https://dmapi.joker.com:443/request/'

    include JokerDMAPI::Contact
    include JokerDMAPI::Domain

    def initialize(username, password)
      @username, @password = username, password
    end

    def self.with_connection(username, password, &block)
      connection = self.new(username, password)
      yield connection
      connection.logout
    end

    def logout
      unless @auth_sid.nil?
        query :logout
        @auth_sid = nil
      end
    end

    private

    def parse_line(line)
      parts = line.split /\s*:\s*/, 2
      if parts.length == 2
        { parts[0].downcase.gsub('-', '_').gsub('.', '_').to_sym => parts[1] }
      else
        line
      end
    end

    def parse_response(response)
      response.each_line { |line| puts "<< #{line}" } if ENV['JOKER_DMAPI_DEBUG']
      parts = response.split("\n\n")
      {
        headers: parts[0].split("\n").inject({}) { |h, line| h.merge! parse_line line },
        body: parts[1]
      }
    end

    def request(request, params = {})
      uri = Addressable::URI.parse(URI + request.to_s)
      uri.query_values = params
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      puts ">> #{uri.request_uri}" if ENV['JOKER_DMAPI_DEBUG']
      parse_response http.request(Net::HTTP::Get.new(uri.request_uri)).body
    end

    def check_status(response)
      if response[:headers][:status_code] != '0'
        raise "#{response[:headers][:status_code]}: #{response[:headers][:error]}\n"
      end
    end

    def auth_sid
      if @auth_sid.nil?
        response = request(:login, username: @username, password: @password)
        check_status response
        @auth_sid = response[:headers][:auth_sid]
      end
      @auth_sid
    end

    def query(request, params = {})
      params['auth-sid'] = auth_sid
      response = request(request, params)
      check_status response
      response
    end

  end
end