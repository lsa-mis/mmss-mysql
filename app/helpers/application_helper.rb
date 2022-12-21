module ApplicationHelper

  def current_camp_year
      CampConfiguration.active_camp_year
  end

  def current_camp_year_app_opens
    if CampConfiguration.active.exists?
      CampConfiguration.active_camp_year_application_open
    else
      "soon"
    end
  end

  def registration_open 
    if CampConfiguration.active.exists?
      Date.today >= CampConfiguration.active_camp_year_application_open && Date.today < CampConfiguration.active_camp_year_application_close
    else
      false
    end
  end

  def new_registration_closed
    if CampConfiguration.active.exists?
      Date.today >= CampConfiguration.active_camp_year_application_close
    else
      false
    end
  end

  def current_enrolled_applicants
      Enrollment.enrolled
  end

  def current_enrollment
    @current_enrollment = current_user.enrollments.current_camp_year_applications.last
  end
  
  def student_packet_url 
    CampConfiguration.active.pick(:student_packet_url)
  end

  def current_camp_fee
    CampConfiguration.active_camp_fee_cents
  end

  def applicant_status
    [
      ['*Select*', ''],
      ['enrolled', 'enrolled'],
      ['application complete', 'application complete'],
      ['offer accepted', 'offer accepted'],
      ['offer declined', 'offer declined'],
      ['submitted', 'submitted']
    ]
  end

  def course_status
    [
      ['open','open'],
      ['closed','closed']
    ]
  end

  def offer_status
    [
      ['*Select*', ''],
      ['accepted', 'accepted'],
      ['declined', 'declined'],
      ['offered', 'offered']
    ]
  end

  def us_states
    [
      ['*Non-US*', 'non-us'],
      ['Alabama', 'AL'],
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'],
      ['California', 'CA'],
      ['Colorado', 'CO'],
      ['Connecticut', 'CT'],
      ['Delaware', 'DE'],
      ['District of Columbia', 'DC'],
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'],
      ['Idaho', 'ID'],
      ['Illinois', 'IL'],
      ['Indiana', 'IN'],
      ['Iowa', 'IA'],
      ['Kansas', 'KS'],
      ['Kentucky', 'KY'],
      ['Louisiana', 'LA'],
      ['Maine', 'ME'],
      ['Maryland', 'MD'],
      ['Massachusetts', 'MA'],
      ['Michigan', 'MI'],
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'],
      ['Missouri', 'MO'],
      ['Montana', 'MT'],
      ['Nebraska', 'NE'],
      ['Nevada', 'NV'],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      ['Ohio', 'OH'],
      ['Oklahoma', 'OK'],
      ['Oregon', 'OR'],
      ['Pennsylvania', 'PA'],
      ['Puerto Rico', 'PR'],
      ['Rhode Island', 'RI'],
      ['South Carolina', 'SC'],
      ['South Dakota', 'SD'],
      ['Tennessee', 'TN'],
      ['Texas', 'TX'],
      ['Utah', 'UT'],
      ['Vermont', 'VT'],
      ['Virginia', 'VA'],
      ['Washington', 'WA'],
      ['West Virginia', 'WV'],
      ['Wisconsin', 'WI'],
      ['Wyoming', 'WY']
    ]
  end

  def campnote_types
    [
      ['Alert','alert'],
      ['Notice','notice']
    ]
  end

  def show_international(international)
    if international
      "yes"
    else
      "no"
    end
  end

  def transportation
    ['Airplane', 'Bus', 'Train', 
      'Automobile - parent or permitted designee is driving me to the University of Michigan campus', 
      'I am a daily MMSS commuter'
    ]
  end

  def show_date(field)
    field.strftime("%A, %d %b %Y") unless field.blank?
  end

  def show_time(field)
    field.strftime("%I:%M %p") unless field.blank?
  end

  def radio_button_checked(object, key, value)
    checked = ""
    unless object.new_record?
      if object.public_send(key) == value
        checked = "checked" 
      end
    end
    return checked
  end

end
