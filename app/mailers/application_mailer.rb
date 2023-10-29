class ApplicationMailer < ActionMailer::Base
  default from: "#{ENV['GMAIL_APP_USER']}@gmail.com"
  layout 'mailer'
end
