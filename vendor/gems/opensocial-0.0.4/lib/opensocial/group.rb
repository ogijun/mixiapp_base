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
  
  # Acts as a wrapper for an OpenSocial group.
  #
  # The Group class takes input JSON as an initialization parameter, and
  # iterates through each of the key/value pairs of that JSON. For each key
  # that is found, an attr_accessor is constructed, allowing direct access
  # to the value. Each value is stored in the attr_accessor, either as a
  # String, Fixnum, Hash, or Array.
  #
  
  
  class Group < Base
    
    # Initializes the Group based on the provided json fragment. If no JSON
    # is provided, an empty object (with no attributes) is created.
    def initialize(json)
      set_values(json)
      if @group
        set_values(@group)
        @group = nil
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
  
  # Provides the ability to request a Collection of groups for a given
  # user.
  #
  # The FetchGroupsRequest wraps a simple request to an OpenSocial
  # endpoint for a collection of groups. As parameters, it accepts
  # a user ID. This request may be used, standalone, by calling send, or
  # bundled into an RpcRequest.
  #
  
  
  class FetchGroupsRequest < Request
    # Defines the service fragment for use in constructing the request URL or
    # JSON
    @@SERVICE = 'groups'
    
    # Initializes a request to fetch groups for the specified user, or the
    # default (@me). A valid Connection is not necessary if the request is to
    # be used as part of an RpcRequest.
    def initialize(connection = nil, guid = '@me')
      super
    end
    
    # Sends the request, passing in the appropriate SERVICE and specified
    # instance variables.
    def send
      json = send_request(@@SERVICE, @guid)
	 
      return parse_response(Group, json['entry'])
    end
  end
  
  # Provides the ability to update the group for a given
  # user or set of users.
  #
  # Wraps a simple Post, Put or Delete request. The parameters are the same as
  # in the Fetch case, + the post_data parameter, which contains the actual
  # data to be updated.
  #
  class UpdateGroupsRequest < Request
  
    # Defines the service fragment for use in constructing the request URL or
    # JSON
    @@SERVICE = 'groups'
    
    # This is only necessary because of a spec inconsistency
    @@RPC_SERVICE = 'groups'
	
	# Initializes a request to update froupfor the specified user and
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