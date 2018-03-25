require "date"

module JokerDMAPI
  module Contact
    CONTACT_REQUIRED = [ :tld, :name, :email, :address_1, :address_2, :city, :postal_code, :country, :phone ]
    CONTACT_ALLOWED = CONTACT_REQUIRED + [ :organization, :state, :fax ]

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
    # [<tt>:address_1</tt>] the contact's main address
    # [<tt>:address_2</tt>] the contact's main secondary address
    # [<tt>:city</tt>] the contact's city
    # [<tt>:state</tt>] the contact's state
    # [<tt>:postal_code</tt>] the contact's postal code
    # [<tt>:country</tt>] the contact's country code (UA)
    # [<tt>:email</tt>] the contact's email address
    # [<tt>:phone</tt>] the contact's voice phone number
    # [<tt>:fax</tt>] the contact's fax number
    # [<tt>:handle</tt>] the contact's handler from Joker
    # [<tt>:created_at</tt>] the date and time of contact created
    # [<tt>:updated_at</tt>] the date and time of contact modified
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
    # [<tt>:address_1</tt>] the contact's main address
    # [<tt>:address_2</tt>] the contact's main secondary address
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
    # [<tt>:address_1</tt>] the contact's main address
    # [<tt>:address_2</tt>] the contact's main secondary address
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
      # fields = contact_prepare(fields)
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
      raise ArgumentError, "TLD must be one of accepted" unless self.tlds.include?(fields[:tld])

      fields[:individual] = 'Yes'
      fields[:individual] = 'No' if fields.key?(:organization) && fields[:organization].present?

      fields
    end
  end
end
