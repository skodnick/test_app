module Remote
  class Response < SimpleDelegator
    def decode_json
      begin
        Oj.load(body, mode: :compat, symbol_keys: true)
      rescue Oj::ParseError
        nil
      end
    end
  end
end

