require "net/http"
require "addressable/uri"
require "#{File.dirname(__FILE__)}/result"
require "#{File.dirname(__FILE__)}/contact"
require "#{File.dirname(__FILE__)}/host"
require "#{File.dirname(__FILE__)}/domain"

module JokerDMAPI
  VERSION = '0.1.3'

  class Client
    DEFAULT_URI = 'https://dmapi.joker.com:443/request/'

    include JokerDMAPI::Result
    include JokerDMAPI::Contact
    include JokerDMAPI::Host
    include JokerDMAPI::Domain

    def initialize(username, password, uri = DEFAULT_URI)
      @username, @password, @uri = username, password, uri
    end

    def self.connection(username, password, uri = DEFAULT_URI, &block)
      connection = self.new(username, password, uri)
      if block_given?
        yield connection
        connection.logout
      else
        connection
      end
    end

    def logout
      unless @auth_sid.nil?
        query :logout
        @auth_sid = nil
      end
    end

    def query(request, params = {})
      response = query_no_raise request, params
      raise_response(response) unless response[:headers][:status_code] == '0'
      response
    end

    def tlds
      auth_sid unless @auth_sid
      @tlds
    end

    private

    def query_no_raise(request, params = {})
      params['auth-sid'] = auth_sid
      request(request, params.inject({}) { |r, (key, value)| r[key.to_s.gsub('_', '-')] = value; r })
    end

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
      request = request.to_s.gsub('_', '-')
      uri = Addressable::URI.parse(@uri + request)
      uri.query_values = params
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      puts ">> #{uri}" if ENV['JOKER_DMAPI_DEBUG']
      parse_response http.request(Net::HTTP::Get.new(uri.request_uri)).body
    end

    def auth_sid
      if @auth_sid.nil?
        response = request(:login, username: @username, password: @password)
        raise "Authentication error" unless response[:headers].has_key? :auth_sid
        @auth_sid = response[:headers][:auth_sid]
        @tlds = response[:body].split "\n"
      end
      @auth_sid
    end

    def raise_response(response)
      raise "\n\n" + response[:headers].inject([]) { |s, (key, value)| s << "#{key}: #{value}"}.join("\n") +
              "\n\n" + response[:body] + "\n\n"
    end
  end
end