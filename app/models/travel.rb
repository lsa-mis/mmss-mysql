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
  before_save :check_transport 

  validates :arrival_transport, :depart_transport, :arrival_session, :depart_session, presence: true

  validates_presence_of :arrival_carrier, :arrival_route_num, :arrival_date, :arrival_time, if: :valid_arrival_transport?
  validates_presence_of :depart_carrier, :depart_route_num, :depart_date, :depart_time,  if: :valid_depart_transport?

  def valid_arrival_transport?
    if self.arrival_transport.include?("Automobile") || self.arrival_transport.include?("commuter")
      false
    else
      true
    end
  end

  def valid_depart_transport?
    if self.depart_transport.include?("Automobile") || self.depart_transport.include?("commuter")
      false
    else
      true
    end
  end

  def check_transport
    if self.arrival_transport.include?("Automobile") || self.arrival_transport.include?("commuter")
      self.arrival_carrier = ''
      self.arrival_route_num = ''
      self.arrival_date = ''
      self.arrival_time = ''
    end
    if self.depart_transport.include?("Automobile") || self.depart_transport.include?("commuter")
      self.depart_carrier = ''
      self.depart_route_num = ''
      self.depart_date = ''
      self.depart_time = ''
    end
  end
end
