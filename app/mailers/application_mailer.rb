class ApplicationMailer < ActionMailer::Base
  default from: "#{ENV['GMAIL_APP_USER'] || 'appname+no-reply'}@#{ ApplicationHelper::APPNAME }.com"
  layout 'mailer'
end
