# == Schema Information
#
# Table name: camp_occurrences
#
#  id                    :bigint           not null, primary key
#  camp_configuration_id :bigint           not null
#  description           :string           not null
#  begin_date            :date             not null
#  end_date              :date             not null
#  active                :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  cost_cents            :integer
#

