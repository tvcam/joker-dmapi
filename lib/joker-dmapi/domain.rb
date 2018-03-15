require "date"

module JokerDMAPI
  module Domain
    # Returns the information about a domain or <tt>nil</tt> if not exists
    #
    # Takes FQDN as string
    #
    # Returned is a hash:
    # [<tt>:fqdn</tt>] FQDN
    # [<tt>:status</tt>] domain status
    # [<tt>:registrant</tt>] registrant (owner) as hash keys:
    #   [<tt>:name</tt>] registrant's name
    #   [<tt>:organization</tt>] registrant's organization
    #   [<tt>:address_1</tt>]
    #   [<tt>:address_2</tt>]
    #   [<tt>:postal_code</tt>] registrant's postal code
    #   [<tt>:country</tt>] registrant's country code
    #   [<tt>:owner_c_email</tt>] owner's email address
    #   [<tt>:email</tt>] registrant's email address
    #   [<tt>:phone</tt>] registrant's voice phone number
    #   [<tt>:fax</tt>] registrant's fax number
    # [<tt>:reseller_lines</tt>] an array of reseller data
    # [<tt>:admin_c</tt>] registrant's admin-c handle
    # [<tt>:tech_c</tt>] registrant's tech-c handle
    # [<tt>:billing_c</tt>] registrant's billing-c handle
    # [<tt>:nservers</tt>] an array of NS servers
    # [<tt>:created_at</tt>] date and time of creation
    # [<tt>:updated_at</tt>] date and time of modification
    # [<tt>:expires</tt>] date and time of expiration
    def domain_info(domain)
      response = query_no_raise :query_whois, domain: domain
      case response[:headers][:status_code]
        when '2303' then nil
        when '0' then
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
                result[:registrant].merge! line_parsed
              when :reseller_line then
                result[:reseller_lines] = [] unless result.has_key? :reseller_lines
                result[:reseller_lines] << value
              when :created_date, :modified_date, :expires then
                key = :created_at if key == :created_date
                key = :updated_at if key == :modified_date

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
        else
          raise_response response
      end
    end

    # Register new domain
    #
    # Takes <tt>domain</tt> and domain's fields as hash:
    # [<tt>:period</tt>] registration period (years!!!)
    # [<tt>:registrant</tt>] registrant (owner) handle (registered)
    # [<tt>:admin</tt>] admin handle (registered)
    # [<tt>:tech</tt>] tech handle (registered)
    # [<tt>:billing</tt>] billing handle (registered)
    # [<tt>:nservers</tt>] an array of NS servers
    #
    # Returned is a hash of response:
    # [<tt>:headers</tt>]
    #   [<tt>:proc_id</tt>] process ID (used at check result)
    #   [<tt>:tracking_id</tt>] tracking ID
    def domain_create(domain, fields)
      unless ([ :period, :registrant, :admin, :tech, :billing, :nservers ] - fields.keys).empty?
        raise ArgumentError, "Required fields not found"
      end
      query :domain_register, {
        domain: domain,
        period: (fields[:period] * 12),
        owner_c: fields[:registrant],
        admin_c: fields[:admin],
        tech_c: fields[:tech],
        billing_c: fields[:billing],
        ns_list: fields[:nservers].join(':')
      }
    end

    # Update domain
    #
    # Takes <tt>domain</tt> and domain's fields as hash:
    # [<tt>:admin</tt>] admin handle (registered)
    # [<tt>:tech</tt>] tech handle (registered)
    # [<tt>:billing</tt>] billing handle (registered)
    # [<tt>:nservers</tt>] an array of NS servers
    #
    # Returned is a hash of response:
    # [<tt>:headers</tt>]
    #   [<tt>:proc_id</tt>] process ID (used at check result)
    #   [<tt>:tracking_id</tt>] tracking ID
    def domain_update(domain, fields)
      unless ([ :admin, :tech, :billing, :nservers ] - fields.keys).empty?
        raise ArgumentError, "Required fields not found"
      end
      query :domain_modify, {
        domain: domain,
        admin_c: fields[:admin],
        tech_c: fields[:tech],
        billing_c: fields[:billing],
        ns_list: fields[:nservers].join(':')
      }
    end

    # Renew domain
    #
    # Takes <tt>domain</tt> and <tt>period</tt>
    # WARNING!!! <tt>period</tt> in YEARS
    def domain_renew(domain, period)
      query :domain_renew, { domain: domain, period: (12 * period) }
    end

    # Update registrant's info
    #
    # Takes <tt>domain</tt> and fields (see contact_update)
    def domain_registrant_update(domain, fields)
      fields = contact_prepare(fields)
      fields[:domain] = domain
      query :domain_owner_change, fields
    end
  end
end
