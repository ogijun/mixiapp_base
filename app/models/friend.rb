class Friend < ActiveRecord::Base
  belongs_to :friend_shipped, :foreign_key=>:friend_id, :class_name => "User"
  belongs_to :befriend_shipped, :foreign_key=>:user_id, :class_name => "User"
end
