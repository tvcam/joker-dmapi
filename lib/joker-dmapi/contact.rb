module JokerDMAPI
  module Contact
    CONTACT_REQUIRED = [ :tld, :name, :email, :address, :city, :postal_code, :country, :phone ]
    CONTACT_ALLOWED = CONTACT_REQUIRED + [ :organization, :state, :fax ]
    CONTACT_LENGTH_LIMIT = %w(biz cn eu)

    def contact_info(handle)
      begin
        response = query 'query-whois', contact: handle
      rescue
        return nil
      end
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

    def contact_create(fields)
      response = query 'contact-create', contact_prepare(fields)
      response[:headers][:proc_id]
    end

    def contact_update(handle, fields)
      fields = contact_prepare(fields)
      fields[:handle] = handle
      response = query 'contact-modify', fields
      query 'result-delete', { 'proc-id' => response[:headers][:proc_id] }
    end

    def contact_create_handle(proc_id)
      response = query 'result-retrieve', { 'proc-id' => proc_id }
      response[:body].split("\n\n", 1)[0].split("\n").each do |line|
        next unless line.match /^Object-Name:\s+(\S+)$/
        response[:handle] = $1
        break
      end
      if response.has_key? :handle and response[:handle] =~ /\d+/
        query 'result-delete', { 'proc-id' => proc_id }
        response[:handle]
      else
        nil
      end
    end

    def contact_delete(handle)
      response = query 'contact-delete', { handle: handle }
      query 'result-delete', { 'proc-id' => response[:headers][:proc_id] }
    end

    private

    def contact_prepare(fields)
      raise ArgumentError, "Required fields not found" unless (CONTACT_REQUIRED - fields.keys).empty?
      auth_sid
      raise ArgumentError, "TLD must be one of accepted" unless @tlds.include? fields[:tld]
      if CONTACT_LENGTH_LIMIT.include? fields[:tld]
        [ :name, :organization, :city, :state ].each do |field|
          next unless fields.has_key? field
          fields[field] = fields[field][0...30] # only 30 allowed
        end
        if fields.has_key? :address
          fields[:address].map! { |addr| addr[0...30] }
        end
      end
      fields = fields.keep_if { |key, value| CONTACT_ALLOWED.include? key }
      if fields.has_key? :organization and !fields[:organization].empty?
        fields[:individual] = 'No'
      else
        fields[:individual] = 'Yes'
      end
      unless fields[:address].size > 0 and fields[:address].size <= 3
        raise ArgumentError, "From one to three lines of address allowed"
      end
      (1..3).each do |index|
        fields["address-" + index.to_s] = fields[:address][index-1].nil? ? '' : fields[:address][index-1]
      end
      fields.delete :address
      fields
    end
  end
end