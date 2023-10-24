class ApplicationMailer < ActionMailer::Base
  default from: "noreply@#{ ApplicationHelper::APPNAME }.com"
  layout 'mailer'
end
