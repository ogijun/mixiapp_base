class User < ActiveRecord::Base
  acts_as_paranoid
  
  has_many :friend_ships, :foreign_key => 'user_id', :class_name => 'Friend'
  has_many :friends, :through => :friend_ships, :source => :friend_shipped, :order => "users.mixi_id asc"
  
  def self.create_or_update(data)
    user = User.find_or_create_by_mixi_id(data["mixi_id"])
    user.update_attributes(data)
    user
  end
end
