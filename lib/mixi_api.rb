require 'json'

class MixiApi
  def initialize(requester)
    container = {
      :endpoint     => AppResources[:api_endpoint],
      :content_type => 'application/json',
      :rest         => ''
    }
    
    if requester.is_a?(User)
      requester_id = requester.mixi_id.to_s
    else
      requester_id = requester.to_s
    end
    
    @connection = OpenSocial::Connection.new(:container => container,
                                 :consumer_key => AppResources[:consumer_key],
                                 :consumer_secret => AppResources[:consumer_secret],
                                 :xoauth_requestor_id => requester_id)
  end
  
  def get_person(guid = '@me', selector = '@self')
    p = OpenSocial::FetchPersonRequest.new(@connection, guid, selector).send
    convert_person(parse_json(p.to_json))
  end
  
  def get_people(guid = '@me', selector = '@friends')
    p = OpenSocial::FetchPeopleRequest.new(@connection, guid, selector).send
    data = parse_json(p.to_json)
    data.each do |k, v|
      data[k] = convert_person(v)
    end
    data.values
  end
  
  def get_activities(guid = '@me', selector = '@self', pid = '@app')
    a = OpenSocial::FetchActivityRequest.new(@connection, guid, selector, pid).send
    parse_json(a.to_json)
  end

  def get_appdata(guid = '@me', selector = '@self', aid = '@app')
    a = OpenSocial::FetchAppDataRequest.new(@connection, guid, selector, pid).send
    parse_json(a.to_json)
  end
  
  def post_activity(data)
    OpenSocial::PostActivityRequest.new(@connection).send(data.to_json) if data
  end
  
  def post_appdata(data)
    OpenSocial::PostAppDataRequest.new(@connection).send(data.to_json) if data
  end
  
  def self.register(request, params, session)
    if request.mobile?
      return false if !params['opensocial_owner_id']
      api = MixiApi.new(params['opensocial_owner_id'])
      owner_data = api.get_person
      friends_data = api.get_people
    else
      json_data = JSON.parse(Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(params['data'].unpack('m')[0]), :create_additions => false)
      owner_data = json_data['owner']
      viewer_data = json_data['viewer']
      friends_data = json_data['friends']
    end
    
    owner = User.create_or_update(owner_data)
    if !viewer_data || viewer_data["mixi_id"] == owner_data["mixi_id"]
      viewer = owner
    else
      viewer = User.create_or_update(viewer_data)
    end
    
    owner.logged_at = Time.now
    if owner == viewer && owner.joined_at.nil?
      owner.joined_at = Time.now
    end
    
    curr_friend_user_ids = []
    friends_data.each do |friend_data|
      next if !friend_data || !friend_data["nickname"] #アプリ使用不可ユーザ
      
      user = User.create_or_update(friend_data)
      owner.friends << user unless owner.friends.member?(user)
      curr_friend_user_ids << user.id
    end
    
    owner.friend_ships.each do |friend_ship|
      friend_ship.destroy unless curr_friend_user_ids.member?(friend_ship.friend_id)
    end
    
    owner.save
    
    session[:viewer] = viewer
    session[:owner] = owner
  end
  
  protected
  def parse_json(data)
    JSON.parse(data, :create_additions => false)
  end
  
  def convert_person(hash)
    {
      'mixi_id' => hash['id'].split(':').last,
      'nickname' => hash['nickname'],
      'thumbnail_url' => hash['thumbnail_url']
    }
  end
end
