# == Schema Information
#
# Table name: enrollments
#
#  id                          :bigint           not null, primary key
#  user_id                     :bigint           not null
#  international               :boolean          default(FALSE), not null
#  high_school_name            :string           not null
#  high_school_address1        :string           not null
#  high_school_address2        :string
#  high_school_city            :string           not null
#  high_school_state           :string
#  high_school_non_us          :string
#  high_school_postalcode      :string
#  high_school_country         :string           not null
#  year_in_school              :string           not null
#  anticipated_graduation_year :string           not null
#  room_mate_request           :string
#  personal_statement          :text             not null
#  notes                       :text
#  application_status          :string
#  offer_status                :string
#  partner_program             :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  campyear                    :integer
#  application_deadline        :date
#
require 'rails_helper'

RSpec.describe Enrollment, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
