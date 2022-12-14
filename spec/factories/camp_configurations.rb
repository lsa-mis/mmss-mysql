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
#  offer_letter              :text(65535)
#  student_packet_url        :string(255)
#  application_fee_cents     :integer
#  reject_letter             :text(65535)
#  waitlist_letter           :text(65535)
#  application_fee_required  :boolean
#
FactoryBot.define do
  factory :camp_configuration do
    camp_year { 2019 }
    application_open { "2019-07-17" }
    application_close { "2019-07-17" }
    priority { "2019-07-17" }
    application_materials_due { "2019-07-17" }
    camper_acceptance_due { "2019-07-17" }
    active { false }
  end
end
