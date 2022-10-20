# == Schema Information
#
# Table name: camp_configurations
#
#  id                        :bigint           not null, primary key
#  camp_year                 :integer          not null
#  application_open          :date             not null
#  application_close         :date             not null
#  priority                  :date             not null
#  application_materials_due :date             not null
#  camper_acceptance_due     :date             not null
#  active                    :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  offer_letter              :text
#  student_packet_url        :string
#  application_fee_cents     :integer
#  reject_letter             :text
#  waitlist_letter           :text
#
require 'rails_helper'

RSpec.describe CampConfiguration, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
