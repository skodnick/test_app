class SponsorPaySettings < Settingslogic
  source "#{Rails.root}/config/sponsor_pay.yml"
  namespace Rails.env
  suppress_errors Rails.env.production?
end
