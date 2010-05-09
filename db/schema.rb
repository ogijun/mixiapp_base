# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091108181419) do

  create_table "app_invites", :force => true do |t|
    t.string   "mixi_id"
    t.string   "invitee_mixi_id"
    t.integer  "invite_status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "app_invites", ["invitee_mixi_id"], :name => "index_app_invites_on_invitee_mixi_id"
  add_index "app_invites", ["mixi_id", "invitee_mixi_id"], :name => "index_app_invites_on_mixi_id_and_invitee_mixi_id", :unique => true

  create_table "friends", :force => true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friends", ["user_id", "friend_id"], :name => "index_friends_on_user_id_and_friend_id", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "mixi_id",       :null => false
    t.string   "nickname"
    t.string   "profile_url"
    t.string   "thumbnail_url"
    t.datetime "joined_at"
    t.datetime "logged_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["mixi_id"], :name => "index_users_on_mixi_id", :unique => true

end
