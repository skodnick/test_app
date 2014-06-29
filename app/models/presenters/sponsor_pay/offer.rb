module Presenters::SponsorPay
  class Offer
    attr_reader :title, :payout, :thumbnail_high, :thumbnail_low

    def initialize(hash)
      hash.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def thumbnail_high
      @thumbnail[:hires]
    end

    def thumbnail_low
      @thumbnail[:lowres]
    end
  end
end
