module JokerDMAPI
  module Result
    # Check result
    #
    # Get <tt>proc_id</tt>
    # Returned <tt>true</tt> if done (result deleted)
    def complete?(proc_id)
      response = result_retrieve(proc_id)
      result = parse_attributes(response[:body].split("\n\n", 1)[0])
      if result.has_key?(:completion_status) and result[:completion_status] == 'ack'
        result_delete proc_id
        true
      elsif result.has_key?(:completion_status) and result[:completion_status] == 'nack'
        result_delete proc_id
        raise_response response
      else
        false
      end
    end

    def result_retrieve(proc_id)
      query 'result-retrieve', { proc_id: proc_id }
    end

    def result_delete(proc_id)
      query 'result-delete', { proc_id: proc_id }
    end

    def raise_response(response)
      raise "\n\n" + response[:headers].inject([]) { |s, (key, value)| s << "#{key}: #{value}"}.join("\n") +
              "\n\n" + response[:body] + "\n\n"
    end
  end
end