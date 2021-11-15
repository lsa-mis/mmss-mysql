# == Schema Information
#
# Table name: users
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
class User < ApplicationRecord
  has_one :applicant_detail, dependent: :destroy, inverse_of: :user
  has_many :enrollments, dependent: :destroy
  before_destroy :archive_associated_payments, prepend: true
  has_many :payments, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :timeoutable


  # def total_paid
  #   payments.pluck(:total_amount).map{ |v| v.to_f }.sum / 100
  # end

  def display_name
    self.email # or whatever column you want
  end

  def archive_associated_payments
    self.payments do |payment|
      archive_attr = payment.attributes.except!("user_id")
      archive_payment = PaymentArchive.new(archive_attr)
      archive_payment.user_email = self.email
      archive_payment.first_name = self.applicant_detail.lastname
      archive_payment.first_name = self.applicant_detail.firstname
      archive_payment.save
    end
  end
end
