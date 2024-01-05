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
#  depart_route_num  :string(255)
#  depart_date       :date
#  depart_time       :time
#  depart_carrier    :string(255)
#  arrival_session   :string(255)
#  depart_session    :string(255)
#
class Travel < ApplicationRecord
  belongs_to :enrollment

  validates :arrival_transport, :depart_transport, :arrival_session, :depart_session, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["arrival_carrier", "arrival_date", "arrival_route_num", "arrival_session", "arrival_time", "arrival_transport", "created_at", "depart_carrier", "depart_date", "depart_route_num", "depart_session", "depart_time", "depart_transport", "enrollment_id", "id", "note", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["enrollment"]
  end
end
