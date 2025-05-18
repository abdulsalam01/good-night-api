require 'rails_helper'

RSpec.describe "SleepRecords", type: :request do
  let!(:alice)   { User.create!(name: "Alice") }
  let!(:bob)     { User.create!(name: "Bob") }
  let!(:charlie) { User.create!(name: "Charlie") }

  before do
    Rails.cache.clear
  end

  describe "POST /users/:user_id/clock_ins" do
    it "creates a new sleep record" do
      post "/users/#{alice.id}/clock_ins", params: { duration: 420 }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["clock_ins"].first["duration"]).to eq(420)
    end

    it "rejects invalid duration" do
      post "/users/#{alice.id}/clock_ins", params: { duration: -10 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Duration must be greater than 0")
    end
  end

  describe "GET /users/:user_id/clock_ins" do
    before do
      6.times { |i| alice.sleep_records.create!(duration: 300 + i * 10) }
    end

    it "paginates with cursor" do
      get "/users/#{alice.id}/clock_ins"
      json = JSON.parse(response.body)

      expect(json["clock_ins"].size).to eq(5)
      expect(json["next_cursor"]).not_to be_nil

      next_cursor = json["next_cursor"]
      get "/users/#{alice.id}/clock_ins", params: { cursor: next_cursor }
      json2 = JSON.parse(response.body)

      expect(json2["clock_ins"].size).to eq(1)
    end
  end

  describe "GET /users/:id/feed" do
    before do
      Follow.create!(follower: alice, followed: bob)
      Follow.create!(follower: alice, followed: charlie)

      bob.sleep_records.create!(duration: 360)
      charlie.sleep_records.create!(duration: 480)
    end

    it "returns feed sorted by created_at desc" do
      get "/users/#{alice.id}/feed"
      expect(response).to have_http_status(:ok)

      records = JSON.parse(response.body)["records"]
      expect(records.size).to eq(2)
      expect(records.first["user_name"]).to eq("Charlie")
      expect(records.last["user_name"]).to eq("Bob")
    end

    it "removes unfollowed user from feed (cache invalidated)" do
      delete "/users/#{alice.id}/follow/#{charlie.id}"

      get "/users/#{alice.id}/feed"
      feed = JSON.parse(response.body)["records"]

      expect(feed.any? { |r| r["user_name"] == "Charlie" }).to be false
      expect(feed.any? { |r| r["user_name"] == "Bob" }).to be true
    end
  end
end
