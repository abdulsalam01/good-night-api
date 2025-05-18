class SleepRecordsController < ApplicationController
  # GET /users/:user_id/clock_ins
  def index
    user = User.find(params[:user_id])
    # Prepare base query for this user's sleep records, newest first.
    records_query = user.sleep_records.order(created_at: :desc)

    # Apply cursor-based pagination if a cursor (last seen record ID) is provided.
    if params[:cursor].present?
      records_query = records_query.where("id < ?", params[:cursor])
    end

    records = records_query.limit(PAGE_SIZE)
    next_cursor = records.size == PAGE_SIZE ? records.last.id : nil

    render json: {
      clock_ins: records.as_json(only: [ :id, :duration, :created_at ]),
      next_cursor: next_cursor
    }
  end

  # POST /users/:user_id/clock_ins
  def create
    user = User.find(params[:user_id])
    sleep_record = user.sleep_records.new(duration: params[:duration])

    if sleep_record.save
      # On success, include the new record in the first page of results.
      records = user.sleep_records.order(created_at: :desc).limit(PAGE_SIZE)
      next_cursor = records.size == PAGE_SIZE ? records.last.id : nil

      render json: {
        clock_ins: records.as_json(only: [ :id, :duration, :created_at ]),
        next_cursor: next_cursor
      }, status: :created
    else
      render json: { errors: sleep_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /users/:id/feed
  def friends_feed
    user = User.find(params[:id])
    # IDs of users that the current user is following.
    followed_ids = user.followed_users.pluck(:id)

    # Get sleep records from followed users in the past 7 days, ordered by duration (desc).
    recent_records = SleepRecord.includes(:user)
                                .where(user_id: followed_ids)
                                .where("created_at >= ?", 7.days.ago)
                                .order(duration: :desc)

    # Use in-memory caching for the feed results to improve performance.
    cache_key = "feed-#{user.id}"
    feed_results = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      # Build an array of sleep records with user info for the feed.
      recent_records.map do |rec|
        {
          user_id: rec.user_id,
          user_name: rec.user.name,
          duration: rec.duration,
          clocked_in_at: rec.created_at
        }
      end
    end

    render json: { feed: feed_results }
  end
end
