require 'spec_helper'

describe Presenters::SponsorPay::Offer do
  let(:offer) do
    { title: 'Tap Fish',
      offer_id: 13554,
      teaser: ' Download and START ',
      required_actions: 'Download and START',
      link: 'http://iframe.sponsorpay.com/mbrowser?appid=157&lpid=11387&uid=player1',
      offer_types: [ { offer_type_id: '101', readable: 'Download' },
                     { offer_type_id: '112', readable:  'Free' } ],
      thumbnail: {
        lowres: 'http://cdn.sponsorpay.com/assets/1808/icon175x175-2_square_60.png',
        hires: 'http://cdn.sponsorpay.com/assets/1808/icon175x175-2_square_175.png' },
      payout: '90',
      time_to_payout: { amount: '1800', readable: '30 minutes' }
    }
  end

  subject { described_class.new(offer) }

  its(:title)  { should eq 'Tap Fish' }
  its(:payout) { should eq '90' }

  its(:thumbnail_high) { should eq 'http://cdn.sponsorpay.com/assets/1808/icon175x175-2_square_175.png' }
  its(:thumbnail_low)  { should eq 'http://cdn.sponsorpay.com/assets/1808/icon175x175-2_square_60.png' }
end
