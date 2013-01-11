module JokerDMAPI
  module Contact
    def contact_info(handle)
      response = query 'query-whois', contact: handle
      result = {}
      response[:body].split("\n").each do |line|
        line.slice! /^contact\./
        line_parsed = parse_line(line)
        next if line_parsed.is_a? String
        key, value = line_parsed.first
        case key
          when :name then next if value == "- -"
          when :address_1, :address_2, :address_3 then
            result[:address] = [] unless result.has_key? :address
            result[:address] << value
          when :state then next if value == "--"
          when :created_date, :modified_date then
            result[key] = DateTime.parse value
          else
            result.merge! line_parsed
        end
      end
      result
    end
  end
end