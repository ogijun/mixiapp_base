class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :mixi_id,      :null => false
      t.string :nickname
      t.string :profile_url
      t.string :thumbnail_url
      t.datetime :joined_at
      t.datetime :logged_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :users, :mixi_id, :unique => true
  end

  def self.down
    drop_table :users
  end
end
