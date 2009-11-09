class AppInvite < ActiveRecord::Base
  const_set('INVITE_STATUS_INVITED',    1) # 招待済み
  const_set('INVITE_STATUS_INSTALLED',  2) # アプリインストール済み
  named_scope :installed, :conditions => ["invite_status = ?", AppInvite::INVITE_STATUS_INSTALLED]
end
