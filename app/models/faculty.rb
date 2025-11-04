# frozen_string_literal: true

# == Schema Information
#
# Table name: faculties
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Faculty < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validate :faculty_has_courses

  private

    def faculty_has_courses
      uniqname = self.email.split('@').first
      unless Course.current_camp.pluck(:faculty_uniqname).uniq.compact.include?(uniqname)
        errors.add(:base, "You don't have any courses, please contact the administrator")
      end
    end
end
