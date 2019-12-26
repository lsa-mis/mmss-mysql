class Recupload < ApplicationRecord
  belongs_to :recommendation

  # validates :letter, length: { minimum: 50 }
  validates :authorname, presence: true
  validates :studentname, presence: true

  has_one_attached :recletter

end
