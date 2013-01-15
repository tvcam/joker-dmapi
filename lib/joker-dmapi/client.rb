require "net/http"
require "addressable/uri"
require "joker-dmapi/result"
require "joker-dmapi/contact"
require "joker-dmapi/domain"

module JokerDMAPI
  VERSION = '0.0.1'

  class Client
    URI = 'https://dmapi.joker.com:443/request/'

    include JokerDMAPI::Result
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

    def query(request, params = {})
      params['auth-sid'] = auth_sid
      response = request(request, params.inject({}) { |r, (key, value)| r[key.to_s.gsub('_', '-')] = value; r })
      check_status response
      response
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

    def parse_attributes(attributes)
      attributes.split("\n").inject({}) do |h, line|
        attribute = parse_line line
        h.merge!(attribute) if attribute.is_a? Hash
        h
      end
    end

    def parse_response(response)
      response.each_line { |line| puts "<< #{line}" } if ENV['JOKER_DMAPI_DEBUG']
      parts = response.split "\n\n", 2
      { headers: parse_attributes(parts[0]), body: parts[1] }
    end

    def request(request, params = {})
      uri = Addressable::URI.parse(URI + request.to_s)
      uri.query_values = params
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
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
        @tlds = response[:body].split "\n"
      end
      @auth_sid
    end
  end
end