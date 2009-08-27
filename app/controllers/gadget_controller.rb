require 'json'

class GadgetController < ApplicationController
  protect_from_forgery :except => ["index", "register", "top", "timeout"]
  before_filter :validate_session, :only => [:top]

  def index
    respond_to do |format|
      format.xml
    end
  end

  def register
    owner_data = JSON.parse(params['owner'])
    viewer_data = JSON.parse(params['viewer'])
    friends_data = JSON.parse(params['friends'])
    
    owner = User.create_or_update(owner_data)
    viewer = User.create_or_update(viewer_data)

    owner.logged_at = Time.now
    if owner == viewer && owner.joined_at.nil?
      owner.joined_at = Time.now
    end
    
    curr_friend_user_ids = []
    friends_data.each do |friend_data|
      next if !friend_data["nickname"] #アプリ使用不可ユーザ
      
      user = User.create_or_update(friend_data)
      owner.friends << user unless owner.friends.member?(user)
      curr_friend_user_ids << user.id
    end

    owner.friend_ships.each do |friend_ship|
      friend_ship.destroy unless curr_friend_user_ids.member?(friend_ship.friend_id)
    end

    owner.save
    
    session[:owner] = User.find(owner.id, :include => :friends)
    session[:viewer] = User.find(viewer.id, :include => :friends)
    
    session[:owner].friends.sort!{|a, b| (a.mixi_id <=> b.mixi_id)}
    session[:viewer].friends.sort!{|a, b| (a.mixi_id <=> b.mixi_id)}
    
    redirect_gadget_to :controller => "gadget", :action => "top"
  end
  
  def top
  end
  
  def home
    render :layout => false
  end

  def profile
    render :layout => false
  end
  
  def preview
    render :layout => false
  end
  
  def timeout
  end
  
  def error
  end

end
