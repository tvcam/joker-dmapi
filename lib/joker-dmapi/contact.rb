require "date"

module JokerDMAPI
  module Contact
    CONTACT_REQUIRED = [ :tld, :name, :email, :address, :city, :postal_code, :country, :phone ]
    CONTACT_ALLOWED = CONTACT_REQUIRED + [ :organization, :state, :fax ]
    CONTACT_LENGTH_LIMIT = %w(biz cn eu)

    # Returns the all contacts or <tt>[]</tt> if not exists
    def query_contact_list
      response = query_no_raise :query_contact_list

      case response[:headers][:status_code]
      when '2303' then []
      when '0' then
        response[:body].split("\n")
      else
        raise_response(response)
      end
    end

    # Returns the information about a contact or <tt>nil</tt> if not exists
    #
    # Takes handler as string
    #
    # Returned is a hash:
    # [<tt>:name</tt>] the contact's name
    # [<tt>:organization</tt>] the contact's organization name
    # [<tt>:address</tt>] an array containing from one to three elements with contact's address
    # [<tt>:city</tt>] the contact's city
    # [<tt>:state</tt>] the contact's state
    # [<tt>:postal_code</tt>] the contact's postal code
    # [<tt>:country</tt>] the contact's country code (UA)
    # [<tt>:email</tt>] the contact's email address
    # [<tt>:phone</tt>] the contact's voice phone number
    # [<tt>:fax</tt>] the contact's fax number
    # [<tt>:handle</tt>] the contact's handler from Joker
    # [<tt>:created_date</tt>] the date and time of contact created
    # [<tt>:modified_date</tt>] the date and time of contact modified
    def contact_info(handle)
      response = query_no_raise :query_whois, contact: handle
      case response[:headers][:status_code]
        when '2303' then nil
        when '0' then
          result = {}
          response[:body].split("\n").each do |line|
            line.slice! /^contact\./
            line_parsed = parse_line(line)
            next if line_parsed.is_a? String

            key, value = line_parsed.first

            case key
            when :created_date, :modified_date then
              key = :created_at if key == :created_date
              key = :updated_at if key == :modified_date

              result[key] = DateTime.parse(value)
            else
              result.merge! line_parsed
            end
          end
          result
        else
          raise_response response
      end
    end

    # Create new contact
    #
    # Takes contact's fields as hash:
    # [<tt>:tld</tt>] the TLD to use new contact
    # [<tt>:name</tt>] the contact's name
    # [<tt>:organization</tt>] the contact's organization name
    # [<tt>:address</tt>] an array containing from one to three elements with contact's address
    # [<tt>:city</tt>] the contact's city
    # [<tt>:state</tt>] the contact's state
    # [<tt>:postal_code</tt>] the contact's postal code
    # [<tt>:country</tt>] the contact's country code (UA)
    # [<tt>:email</tt>] the contact's email address
    # [<tt>:phone</tt>] the contact's voice phone number
    # [<tt>:fax</tt>] the contact's fax number
    #
    # Returned is a hash of response:
    # [<tt>:headers</tt>]
    #   [<tt>:proc_id</tt>] process ID (used at check result)
    #   [<tt>:tracking_id</tt>] tracking ID
    def contact_create(fields)
      query :contact_create, contact_prepare(fields)
    end

    # Check result of create contact
    #
    # Get <tt>proc_id</tt>
    # Returned contact's handle name (and delete result) or <tt>nil</tt> if don't ready
    def contact_create_result(proc_id)
      result = parse_attributes(result_retrieve(proc_id)[:body].split("\n\n", 1)[0])
      return nil unless result.has_key? :completion_status
      case result[:completion_status]
        when 'ack' then
          result_delete proc_id
          result[:object_name]
        when 'nack' then
          raise_response response
        else
          nil
      end
    end

    # Update contact
    #
    # Takes <tt>handle</tt> to select contact and contact's fields as hash:
    # [<tt>:name</tt>] the contact's name
    # [<tt>:organization</tt>] the contact's organization name
    # [<tt>:address</tt>] an array containing from one to three elements with contact's address
    # [<tt>:city</tt>] the contact's city
    # [<tt>:state</tt>] the contact's state
    # [<tt>:postal_code</tt>] the contact's postal code
    # [<tt>:country</tt>] the contact's country code (UA)
    # [<tt>:email</tt>] the contact's email address
    # [<tt>:phone</tt>] the contact's voice phone number
    # [<tt>:fax</tt>] the contact's fax number
    #
    # Returned is a hash of response:
    # [<tt>:headers</tt>]
    #   [<tt>:proc_id</tt>] process ID (used at check result)
    #   [<tt>:tracking_id</tt>] tracking ID
    def contact_update(handle, fields)
      fields = contact_prepare(fields)
      fields[:handle] = handle
      query 'contact-modify', fields
    end

    # Delete contact
    # Takes <tt>handle</tt>
    def contact_delete(handle)
      query 'contact-delete', { handle: handle }
    end

    private

    def contact_prepare(fields)
      raise ArgumentError, "Required fields not found" unless (CONTACT_REQUIRED - fields.keys).empty?
      raise ArgumentError, "TLD must be one of accepted" unless self.tlds.include? fields[:tld]
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
