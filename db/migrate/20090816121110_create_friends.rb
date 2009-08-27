class CreateFriends < ActiveRecord::Migration
  def self.up
    create_table :friends do |t|
      t.integer :user_id
      t.integer :friend_id

      t.timestamps
    end
    add_index :friends, [:user_id, :friend_id], :unique => true
  end

  def self.down
    drop_table :friends
  end
end
