class CreateFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :follows do |t|
      t.integer :follower_id, null: false
      t.integer :followed_id, null: false

      t.timestamps
    end

    # Add foreign key constraints for data integrity.
    add_foreign_key :follows, :users, column: :follower_id
    add_foreign_key :follows, :users, column: :followed_id

    # Index to ensure quick lookup and uniqueness on follower-followed pairs
    add_index :follows, [ :follower_id, :followed_id ], unique: true
    # Additional index to query all followers of a user.
    add_index :follows, :followed_id
  end
end
