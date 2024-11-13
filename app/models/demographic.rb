# frozen_string_literal: true

# == Schema Information
#
# Table name: demographics
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  protected   :boolean          default(FALSE)
#
class Demographic < ApplicationRecord
  before_validation :normalize_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 2250 }

  scope :modifiable, -> { where(protected: false) }

  before_destroy :prevent_protected_deletion

  validate :name_format

  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end

  def prevent_protected_deletion
    return unless protected?

    errors.add(:base, 'Cannot delete protected demographic options')
    throw :abort
  end

  def name_format
    return unless name.present?

    errors.add(:name, 'cannot contain punctuation') if name =~ /[[:punct:]]/

    return unless name =~ /\s{2,}/

    errors.add(:name, 'cannot contain consecutive spaces')
  end
end
