# == Schema Information
#
# Table name: travels
#
#  id                :bigint           not null, primary key
#  enrollment_id     :bigint           not null
#  arrival_transport :string(255)
#  arrival_carrier   :string(255)
#  arrival_route_num :string(255)
#  note              :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  arrival_date      :date
#  arrival_time      :time
#  depart_transport  :string(255)
#  depart_route_num  :time
#  depart_date       :date
#  depart_time       :time
#  depart_carrier    :string(255)
#  arrival_session   :string(255)
#  depart_session    :string(255)
#
FactoryBot.define do
  factory :travel do
    enrollment { nil }
    direction { "MyString" }
    transport_needed { "MyString" }
    date { "2019-09-24 16:54:31" }
    mode { "MyString" }
    carrier { "MyString" }
    route_num { "MyString" }
    note { "MyText" }
  end
end
