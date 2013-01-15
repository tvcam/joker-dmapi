module JokerDMAPI
  module Result
    def result_retrieve(proc_id)
      query 'result-retrieve', { proc_id: proc_id }
    end

    def result_delete(proc_id)
      query 'result-delete', { proc_id: proc_id }
    end
  end
end