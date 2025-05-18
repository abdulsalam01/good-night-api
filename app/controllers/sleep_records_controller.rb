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
    cursor = params[:cursor].to_i if params[:cursor].present?

    # Step 1: Cache key includes user ID and cursor for pagination.
    cache_key = "feed/#{user.id}/#{cursor || 'first'}"

    feed_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      # Step 2: Get followed user IDs.
      followed_ids = user.followed_users.pluck(:id)

      # Step 3: Build base query.
      query = SleepRecord
        .includes(:user)
        .where(user_id: followed_ids)
        .where("created_at >= ?", 7.days.ago)
        .order(duration: :desc, id: :desc) # Add ID for tie-breaker.

      # Step 4: Apply cursor if present.
      if cursor.present?
        last_record = SleepRecord.find_by(id: cursor)
        if last_record
          query = query.where(
            "duration < ? OR (duration = ? AND id < ?)",
            last_record.duration, last_record.duration, last_record.id
          )
        end
      end

      # Step 5: Limit results for pagination.
      records = query.limit(FEED_PAGE_SIZE).to_a

      # Step 6: Format results and include next_cursor.
      {
        records: records.map { |rec| serialize_feed_record(rec) },
        next_cursor: records.size == FEED_PAGE_SIZE ? records.last.id : nil
      }
    end

    render json: feed_data
  end

  private

  def serialize_feed_record(record)
    {
      id: record.id,
      user_id: record.user_id,
      user_name: record.user.name,
      duration: record.duration,
      clocked_in_at: record.created_at
    }
  end
end
