module JokerDMAPI
  module Result
    # Check result
    #
    # Get <tt>proc_id</tt>
    # Returned <tt>true</tt> if done (result deleted)
    def complete?(proc_id)
      result = parse_attributes(result_retrieve(proc_id)[:body].split("\n\n", 1)[0])
      if result.has_key?(:completion_status) and result[:completion_status] == 'ack'
        result_delete proc_id
        true
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
  end
end