# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 13) do

  create_table "deferred_actions", :force => true do |t|
    t.string   "secret",       :null => false
    t.integer  "actor_id",     :null => false
    t.string   "action"
    t.text     "args"
    t.string   "redirection"
    t.datetime "expires_at"
    t.datetime "performed_at"
    t.text     "error"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "identities", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "type"
    t.integer  "user_id"
    t.text     "serialized"
    t.datetime "followed_at"
    t.datetime "confirmed_at"
  end

  add_index "identities", ["email"], :name => "index_identities_on_email", :unique => true
  add_index "identities", ["name", "type"], :name => "index_identities_on_name_and_type", :unique => true
  add_index "identities", ["user_id", "id", "type"], :name => "index_identities_on_user_id_and_id_and_type", :unique => true

  create_table "offers", :force => true do |t|
    t.text     "description", :null => false
    t.integer  "owner_id",    :null => false
    t.integer  "quest_id",    :null => false
    t.integer  "compliance",  :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "image"
    t.string   "location"
    t.text     "serialized"
  end

  add_index "offers", ["owner_id"], :name => "index_offers_on_owner_id"
  add_index "offers", ["quest_id"], :name => "index_offers_on_quest_id"

  create_table "quests", :force => true do |t|
    t.string   "title",                             :null => false
    t.text     "description",                       :null => false
    t.integer  "bounty_in_cents",                   :null => false
    t.integer  "owner_id"
    t.datetime "started_at"
    t.datetime "expires_at"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.text     "image"
    t.string   "visibility"
    t.string   "location"
    t.text     "serialized"
    t.integer  "number_of_criteria", :default => 0, :null => false
  end

  add_index "quests", ["owner_id"], :name => "index_quests_on_user_id"
  add_index "quests", ["visibility"], :name => "index_quests_on_visibility"

  create_table "users", :force => true do |t|
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "remember_token"
  end

  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

end
