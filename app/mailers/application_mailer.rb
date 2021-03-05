class ApplicationMailer < ActionMailer::Base

  default from: "Wavelix <#{ Rails.env.development? ? ENV.fetch('DEVELOPMENT_EMAIL_ALIAS') : ENV.fetch('PRODUCTION_EMAIL_ALIAS')  }>"

  default reply_to: '<>'

  layout 'mailer'

end
