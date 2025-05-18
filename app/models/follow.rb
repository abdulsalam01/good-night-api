class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  # Ensure a user can't follow the same person twice.
  validates :followed_id, uniqueness: { scope: :follower_id, message: "already followed" }
  # Prevent a user from following themselves
  validate :cannot_follow_self

  private

  def cannot_follow_self
    if follower_id == followed_id
      errors.add(:followed, "can't be yourself")
    end
  end
end
