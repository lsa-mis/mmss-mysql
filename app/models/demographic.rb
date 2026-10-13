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

  # standard:disable Rails/UniqueValidationWithoutIndex -- no DB index yet; adding one is a schema change (see #275 for the payments precedent)
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :description, presence: true, uniqueness: {case_sensitive: false}, length: {maximum: 2250}
  # standard:enable Rails/UniqueValidationWithoutIndex

  scope :modifiable, -> { where(protected: false) }

  before_destroy :prevent_protected_deletion

  validate :name_format

  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end

  def prevent_protected_deletion
    return unless protected?

    errors.add(:base, "Cannot delete protected demographic options")
    throw :abort
  end

  def name_format
    return if name.blank?

    errors.add(:name, "cannot contain punctuation") if /[[:punct:]]/.match?(name)

    return unless /\s{2,}/.match?(name)

    errors.add(:name, "cannot contain consecutive spaces")
  end
end
