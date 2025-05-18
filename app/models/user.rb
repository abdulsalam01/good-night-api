class User < ApplicationRecord
  # A user can have many sleep records.
  has_many :sleep_records, dependent: :destroy

  # A user can follow many others (followed_users through follow relationships).
  has_many :following_relationships, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :following_relationships, source: :followed

  # A user can be followed by many others (followers through follow relationships).
  has_many :follower_relationships, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
  has_many :followers, through: :follower_relationships, source: :follower

  validates :name, presence: true
end
