# frozen_string_literal: true

# == Schema Information
#
# Table name: campnotes
#
#  id         :bigint           not null, primary key
#  note       :string(255)
#  opendate   :datetime
#  closedate  :datetime
#  notetype   :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :campnote do
    note { Faker::Lorem.paragraph }
    notetype { 'general' }
    opendate { 1.week.from_now }
    closedate { 2.weeks.from_now }
  end
end
