require 'rails_helper'

RSpec.describe "Follows API", type: :request do
  let!(:alice)   { User.create!(name: "Alice") }
  let!(:bob)     { User.create!(name: "Bob") }
  let!(:charlie) { User.create!(name: "Charlie") }

  before do
    Rails.cache.clear
  end

  describe "POST /users/:id/follow/:followed_id" do
    it "allows a user to follow another user" do
      post "/users/#{alice.id}/follow/#{bob.id}"
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["follower_id"]).to eq(alice.id)
      expect(json["followed_id"]).to eq(bob.id)
    end

    it "prevents duplicate follow relationships" do
      Follow.create!(follower: alice, followed: bob)
      post "/users/#{alice.id}/follow/#{bob.id}"
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Followed already followed")
    end

    it "prevents a user from following themselves" do
      post "/users/#{alice.id}/follow/#{alice.id}"
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Followed can't be yourself")
    end

    it "returns 404 if followed user doesn't exist" do
      post "/users/#{alice.id}/follow/99999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /users/:id/follow/:followed_id" do
    it "unfollows a user successfully" do
      Follow.create!(follower: alice, followed: bob)
      delete "/users/#{alice.id}/follow/#{bob.id}"
      expect(response).to have_http_status(:no_content)
      expect(alice.followed_users).not_to include(bob)
    end

    it "returns 404 if no follow relationship exists" do
      delete "/users/#{alice.id}/follow/#{charlie.id}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
