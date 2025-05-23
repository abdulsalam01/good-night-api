class FollowsController < ApplicationController
  # POST /users/:id/follow/:followed_id
  def create
    follower = User.find(params[:id])
    followed = User.find(params[:followed_id])
    follow = Follow.new(follower: follower, followed: followed)

    if follow.save
      render json: { follower_id: follow.follower_id, followed_id: follow.followed_id }, status: :created
    else
      render json: { errors: follow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id/follow/:followed_id
  def destroy
    follower = User.find(params[:id])
    followed = User.find(params[:followed_id])

    # Find the follow relationship; use find_by! to trigger RecordNotFound if not exists.
    follow = Follow.find_by!(follower: follower, followed: followed)

    follow.destroy
    expire_feed_cache(follower.id)
    head :no_content  # 204 No Content on successful deletion.
  end

  private

  def expire_feed_cache(user_id)
    # Invalidate first page (you can add more granular keys if needed)
    Rails.cache.delete("feed/#{user_id}/first")
  end
end
