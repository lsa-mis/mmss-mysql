module DemographicsHelper
  def demographic_description(applicant_detail)
    if applicant_detail.demographic.blank?
      'None Selected'
    else
      Demographic.find(applicant_detail.demographic).name
    end
  end
end
