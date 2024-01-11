class ApplicationMailer < ActionMailer::Base
  default from: 'MMSS Admin <mmss-support@umich.edu>'
  default bcc: 'MMSS Office <mmss@umich.edu>'
  layout 'mailer'
end
