module Remote::SponsorPay
  class OffersRequest
    include ::ActiveModel::Validations

    attr_reader :uid, :pub0, :page, :params

    validates :uid, presence: true
    validates :page, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    def initialize(uid, pub0 = '', page = 1)
      @uid  = uid
      @pub0 = pub0
      @page = page

      @params = build_params
    end

    def self.perform(uid, pub0 = '', page = 1)
      new(uid, pub0, page).perform
    end

    def perform
      # Pass params as part of URL string because Faraday escapes spaces in params using `+`.
      answer = Remote::Client.get("#{url}?#{params}")
      response = answer[:response]

      if response && response.status == 200
        signature = Digest::SHA1.hexdigest("#{response.body}#{api_key}")
        if response.headers['X-Sponsorpay-Response-Signature'] == signature
          if parsed_body = response.decode_json
            offers = Array(parsed_body[:offers]).map { |hash| Presenters::SponsorPay::Offer.new(hash) }
            answer.slice(:response_time).merge(offers: offers)
          else
            { error: 'Malformed response body' }
          end
        else
          { error: 'Signature error' }
        end
      else
        { error: answer[:error] }
      end
    end

    private

    # The trick is `to_query` method escapes space as plus `+` symbol, but it seems SponsorPay API expects space escaped as `%20`.
    # CGI module uses plus to escape/unescape space, while URI uses `%20` to escape/unescape space.
    def build_params
      params = { uid: uid, pub0: pub0, page: page, timestamp: Time.zone.now.to_i }.merge(SponsorPaySettings.app_params.symbolize_keys)

      # First transform hash to sorted query and unescape string using CGI to remove potential `+` symbols.
      joined_params = CGI.unescape(params.to_query)

      # Then make a hashkey.
      hashkey = Digest::SHA1.hexdigest("#{joined_params}&#{api_key}")

      # And finally make final query with escaped spaces as `%20`.
      "#{URI.escape(joined_params)}&hashkey=#{hashkey}"
    end

    def api_key
      SponsorPaySettings.api_key
    end

    def url
      SponsorPaySettings.url
    end
  end
end
