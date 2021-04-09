class ApplicationMailer < ActionMailer::Base

  default from: "#{Rails.env.development? ? ENV.fetch('DEVELOPMENT_EMAIL_ALIAS') : ENV.fetch('PRODUCTION_EMAIL_ALIAS')}"

  layout 'mailer'

end
