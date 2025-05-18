class SleepRecord < ApplicationRecord
  belongs_to :user

  validates :duration, presence: true,
                      numericality: { only_integer: true, greater_than: 0 }
end
