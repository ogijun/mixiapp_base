require 'configatron'

class MixiApi
  def initialize(requester)
    container = {
      :endpoint     => configatron.api_endpoint,
      :content_type => 'application/json',
      :rest         => ''
    }
    
    if requester.is_a?(User)
      requester_id = requester.mixi_id.to_s
    else
      requester_id = requester.to_s
    end
    
    @connection = OpenSocial::Connection.new(:container => container,
                                 :consumer_key => configatron.consumer_key,
                                 :consumer_secret => configatron.consumer_secret,
                                 :xoauth_requestor_id => requester_id)
  end
  
  def get_person(guid = '@me', selector = '@self', options = {})
    p = OpenSocial::FetchPersonRequest.new(@connection, guid, selector, options).send
    convert_person(parse_json(p.to_json))
  end
  
  def get_people(guid = '@me', selector = '@friends', options = {})
    p = OpenSocial::FetchPeopleRequest.new(@connection, guid, selector, options).send
    data = parse_json(p.to_json)
    data.each do |k, v|
      data[k] = convert_person(v)
    end
    data.values
  end
  
  def get_activities(guid = '@me', selector = '@self', pid = '@app', options = {})
    a = OpenSocial::FetchActivityRequest.new(@connection, guid, selector, pid, options).send
    parse_json(a.to_json)
  end

  def get_appdata(guid = '@me', selector = '@self', aid = '@app', options = {})
    a = OpenSocial::FetchAppDataRequest.new(@connection, guid, selector, pid, options).send
    parse_json(a.to_json)
  end
  
  def post_activity(data)
    OpenSocial::PostActivityRequest.new(@connection).send(data.to_json) if data
  end
  
  def post_appdata(data)
    OpenSocial::PostAppDataRequest.new(@connection).send(data.to_json) if data
  end
  
  def self.register_user(session, owner_data, viewer_data = nil)
    owner = User.create_or_update(owner_data)
    if !viewer_data || viewer_data["mixi_id"] == owner.mixi_id
      viewer = owner
    else
      viewer = User.create_or_update(viewer_data)
    end
    
    if owner == viewer
      owner.logged_at = Time.current
      if owner.joined_at.nil?
        owner.joined_at = Time.current
        
        app_invites = AppInvite.find_all_by_invitee_mixi_id(owner.mixi_id)
        app_invites.each do |app_invite|
          app_invite.invite_status = AppInvite::INVITE_STATUS_INSTALLED
          app_invite.save
        end
      end
      owner.save
    end
    
    session[:viewer] = viewer
    session[:owner] = owner
  end

  def self.register_friends(session, friends_data)
    friends_data.each do |friend_data|
      next if !friend_data || !friend_data["nickname"] #アプリ使用不可ユーザ
      user = User.create_or_update(friend_data)
    end
  end
  
  def self.register_friendships(session, friend_mixi_ids)
    owner = session[:owner].dup
    owner.friends = User.find(:all, :conditions => ["mixi_id in (?)", friend_mixi_ids], :select => "id, mixi_id")
    owner.save
  end
  
  def self.register_invite(session, invite_mixi_ids)
    owner = session[:owner].dup
    invite_mixi_ids.each do |invite_mixi_id|
      app_invite = AppInvite.find_or_initialize_by_mixi_id_and_invitee_mixi_id(owner.mixi_id, invite_mixi_id)
      app_invite.invite_status = AppInvite::INVITE_STATUS_INVITED
      app_invite.save
    end
  end
  
  def self.register_mobile(session, owner_id)
    return if !owner_id
    
    api = self.new(owner_id)
    owner_data = api.get_person('@me', '@self', {})
    friends_data = api.get_people('@me', '@friends', {:count => 1000})
    
	self.register_user(session, owner_data)
	self.register_friends(session, friends_data)
	self.register_friendships(session, friends_data.collect{|friend_data| friend_data['mixi_id']})
  end
  
  protected
  def parse_json(data)
    data.is_a?(Hash) ? data : JSON.parse(data, :create_additions => false)
  end
  
  def convert_person(hash)
    {
      'mixi_id' => hash['id'].split(':').last,
      'nickname' => hash['nickname'],
      'thumbnail_url' => hash['thumbnail_url']
    }
  end
end
