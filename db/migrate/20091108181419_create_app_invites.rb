class CreateAppInvites < ActiveRecord::Migration
  def self.up
    create_table :app_invites do |t|
      t.string :mixi_id
      t.string :invitee_mixi_id
      t.integer :invite_status

      t.timestamps
    end
    add_index :app_invites, [:mixi_id, :invitee_mixi_id], :unique => true
    add_index :app_invites, [:invitee_mixi_id]
  end

  def self.down
    drop_table :app_invites
  end
end
