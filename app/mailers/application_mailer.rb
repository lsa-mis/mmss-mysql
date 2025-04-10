class ApplicationMailer < ActionMailer::Base
  include EmailErrorHandler

  default from: 'University of Michigan - Michigan Math and Science Scholars <no-reply@math.lsa.umich.edu>',
          bcc: 'MMSS Office <mmss@umich.edu>',
          reply_to: 'MMSS Support <mmss-support@umich.edu>'

  layout 'mailer'

  before_action :attach_logo

  def default_url_options
    if Rails.env.production?
      { host: 'mmss-registration.math.lsa.umich.edu', protocol: 'https' }
    else
      { host: 'localhost:3000', protocol: 'http' }
    end
  end

  private

  def attach_logo
    attachments.inline['U-M_Logo.svg'] = File.read(Rails.root.join('app/assets/images/U-M_Logo.svg'))
  end
end
