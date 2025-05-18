class CreateSleepRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :sleep_records do |t|
      t.integer :duration
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end

    # Index for quickly querying a user's sleep records by creation time (newest first).
    add_index :sleep_records, [ :user_id, :created_at ]
  end
end
