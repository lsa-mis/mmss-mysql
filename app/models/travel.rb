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
#
class Travel < ApplicationRecord
  belongs_to :enrollment
end
