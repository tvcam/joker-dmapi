require "resolv"
require "date"

module JokerDMAPI
  module Host
    def host_info(host)
      response = query_no_raise :query_whois, { host: host }
      case response[:headers][:status_code]
        when '2303' then nil
        when '0' then
          result = {}
          response[:body].split("\n").each do |line|
            line.slice! /^host\./
            line_parsed = parse_line(line)
            next if line_parsed.is_a? String
            key, value = line_parsed.first
            case key
              when :fqdn then result[:host] = value
              when :ip_address then result[:ipv4] = value
              when :ip_address_v6 then result[:ipv6] = value
              when :created_date, :modified_date then
                result[key] = DateTime.parse value
              else
                result.merge! line_parsed
            end
          end
          result
        else
          raise_response response
      end
    end

    def host_create(host, fields)
      host_request :ns_create, host, fields
    end

    def host_update(host, fields)
      host_request :ns_modify, host, fields
    end

    private

    def host_request(request, host, fields)
      unless fields.has_key?(:ipv4)
        raise ArgumentError, "Required fields not found"
      end
      p = { host: host }
      p[:ip] = fields[:ipv4] unless fields[:ipv4].empty?
      p[:ipv6] = fields[:ipv6] if fields.has_key? :ipv6
      query request, p
    end

  end
end