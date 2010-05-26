# Copyright (c) 2008 Google Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module OpenSocial #:nodoc:

  class Message < Base
  
	def initialize(json)
      set_values(json)
      if @message
        set_values(@message)
        @message = nil
      end
    end
	
	def set_values(json)
      if json
        json.each do |key, value|
          proper_key = key.snake_case
          begin
            self.send("#{proper_key}=", value)
          rescue NoMethodError
            add_attr(proper_key)
            self.send("#{proper_key}=", value)
          end
        end
      end
    end
	
  end

  # Provides the ability to request a Collection of messages for a given
  # user or set of users.
  #
  # *** NOTE***
  #This operation (Get) may not be supported by the 0.9 spec. The class
  # is provided for completeness.
  #
  # The FetchMessagesRequest wraps a simple request to an OpenSocial
  # endpoint for a Collection of messages. As parameters, it accepts
  # a user ID and selector .
  # This request may be used, standalone, by calling send, or bundled into
  # an RpcRequest.
  #
  class FetchMessagesRequest < Request
  
    # Defines the service fragment for use in constructing the request URL or
    # JSON
    @@SERVICE = 'messaging'
    
    # This is only necessary because of a spec inconsistency
    @@RPC_SERVICE = 'messaging'
	
	# Initializes a request to fetch messages for the specified user and
    # group, or the default (@me, @self). A valid Connection is not necessary
    # if the request is to be used as part of an RpcRequest.
    def initialize(connection = nil, guid = '@me', selector = '@self',
                   pid = nil)
      super(connection, guid, selector, pid)
    end
	
	# Sends the request, passing in the appropriate SERVICE and specified
    # instance variables.
    def send
      json = send_request(@@SERVICE, @guid, @selector, @pid)

      return parse_response(Message, json['entry'])
    end
	
	# Selects the appropriate fragment from the JSON response in order to
    # create a native object.
    def parse_rpc_response(response)
      return parse_response(Message, response['data'])
    end
	
	# Converts the request into a JSON fragment that can be used as part of a
    # larger RpcRequest.
    def to_json(*a)
      value = {
        'method' => @@RPC_SERVICE + @@GET,
        'params' => {
          'userId' => ["#{@guid}"],
          'groupId' => "#{@selector}",
          'appId' => "#{@pid}",
		  'fields' => []
        },
        'id' => @key
      }.to_json(*a)
    end
  end
  
  # Provides the ability to update the message for a given
  # user or set of users.
  #
  # Wraps a simple Post, Put or Delete request. The parameters are the same as
  # in the Fetch case, + the post_data parameter, which contains the actual
  # data to be updated.
  #
  class UpdateMessagesRequest < Request
  
    # Defines the service fragment for use in constructing the request URL or
    # JSON
    @@SERVICE = 'messaging'
    
    # This is only necessary because of a spec inconsistency
    @@RPC_SERVICE = 'messaging'
	
	# Initializes a request to update message(s) for the specified user and
    # group, or the default (@me, @self). A valid Connection is not necessary
    # if the request is to be used as part of an RpcRequest.
    def initialize(connection = nil, guid = '@me', selector = '@self',
                   pid = nil)
      super(connection, guid, selector, pid)
    end
	
	# Sends the request, passing in the appropriate SERVICE and specified
    # instance variables.
    def send(post_data)
      json = send_request(@@SERVICE, @guid, @selector, @pid, post_data)

      return json['statusLink']
    end
  end
  
end