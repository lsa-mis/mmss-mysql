class ApplicationMailer < ActionMailer::Base
  include EmailErrorHandler

  default from: 'University of Michigan MMSS High School Summer Program <no-reply@math.lsa.umich.edu>',
          bcc: 'MMSS Office <mmss@umich.edu>',
          reply_to: 'MMSS Support <mmss-support@umich.edu>'

  layout 'mailer'
end
