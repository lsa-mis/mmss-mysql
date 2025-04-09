class RecuploadMailerPreview < ActionMailer::Preview
  def received_email
    # Create sample data
    recupload = Recupload.new(
      recommendation_id: 1
    )

    RecuploadMailer.with(recupload: recupload).received_email
  end

  def applicant_received_email
    # Create sample data
    recupload = Recupload.new(
      recommendation_id: 1
    )

    RecuploadMailer.with(recupload: recupload).applicant_received_email
  end
end
