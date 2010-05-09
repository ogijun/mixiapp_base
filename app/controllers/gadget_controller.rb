class GadgetController < ApplicationController
  caches_page :index
  before_filter :validate_session, :only => [:register_friends, :register_friendships, :top]
  
  def index
    respond_to do |format|
      format.xml
    end
  end
  
  def register_user
    MixiApi.register_user(session, JSON.parse(params['owner'], :create_additions => false), JSON.parse(params['viewer'], :create_additions => false))
    render :layout => false
  end
  
  def register_friends
    MixiApi.register_friends(session, JSON.parse(params['friends'], :create_additions => false))
    render :layout => false
  end
  
  def register_friendships
    MixiApi.register_friendships(session, JSON.parse(params['friend_mixi_ids'], :create_additions => false))
    render :layout => false
  end
  
  def register_invite
    MixiApi.register_invite(session, JSON.parse(params['invite_mixi_ids'], :create_additions => false))
    render :layout => false
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
