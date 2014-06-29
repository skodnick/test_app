class OffersController < ApplicationController
  def index
    if (query = params['query']).present?
      offers_request = Remote::SponsorPay::OffersRequest.new(query[:uid], query[:pub0], query[:page])

      if offers_request.valid?
        @offers, error, @response_time = offers_request.perform.values_at(:offers, :error, :response_time)
        @errors = Array(error)
      else
        @errors = offers_request.errors.full_messages
      end
    end
  end
end
