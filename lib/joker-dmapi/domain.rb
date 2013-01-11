module JokerDMAPI
  module Domain
    def domain_info(domain)
      begin
        response = query 'query-whois', domain: domain
      rescue
        return nil
      end
      result = {}
      response[:body].split("\n").each do |line|
        line.slice! /^domain\./
        line_parsed = parse_line(line)
        next if line_parsed.is_a? String
        key, value = line_parsed.first
        case key
          when :fqdn, :status then result.merge! line_parsed
          when :name, :organization, :city, :postal_code, :country, :owner_c_email, :email, :phone, :fax then
            result[:registrant] = {} unless result.has_key? :registrant
            result[:registrant].merge! line_parsed
          when :address_1, :address_2, :address_3 then
            result[:registrant] = {} unless result.has_key? :registrant
            result[:registrant][:address] = [] unless result[:registrant].has_key? :address
            result[:registrant][:address] << value
          when :reseller_line then
            result[:reseller_lines] = [] unless result.has_key? :reseller_lines
            result[:reseller_lines] << value
          when :created_date, :modified_date, :expires then
            result[key] = DateTime.parse value
          when :admin_c, :tech_c, :billing_c then
            result.merge! line_parsed
          when :nservers_nserver_handle then
            result[:nservers] = [] unless result.has_key? :nservers
            result[:nservers] << value
          else
            next
        end
      end
      result
    end
  end
end