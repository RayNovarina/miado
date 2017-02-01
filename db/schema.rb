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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170130021849) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "pg_stat_statements"

  create_table "channels", force: :cascade do |t|
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "team_id"
    t.string   "slack_channel_name"
    t.string   "slack_channel_id"
    t.string   "slack_user_id"
    t.string   "slack_team_id"
    t.string   "slack_user_api_token"
    t.string   "bot_api_token"
    t.jsonb    "members_hash"
    t.string   "bot_user_id"
    t.jsonb    "auth_json"
    t.jsonb    "auth_params_json"
    t.jsonb    "rtm_start_json"
    t.datetime "taskbot_msg_date"
    t.datetime "reinstalled_at"
    t.string   "taskbot_msg_to_slack_id"
    t.string   "last_activity_type"
    t.datetime "last_activity_date"
    t.jsonb    "slack_messages"
    t.boolean  "is_taskbot",              default: false
    t.jsonb    "after_action_parse_hash"
    t.boolean  "is_dm_channel",           default: false
  end

  add_index "channels", ["team_id"], name: "index_channels_on_team_id", using: :btree

  create_table "installations", force: :cascade do |t|
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "slack_user_id"
    t.string   "slack_team_id"
    t.string   "slack_user_api_token"
    t.string   "bot_api_token"
    t.string   "bot_user_id"
    t.string   "last_activity_type"
    t.datetime "last_activity_date"
    t.jsonb    "rtm_start_json"
    t.jsonb    "auth_json"
    t.jsonb    "auth_params_json"
  end

  create_table "list_items", force: :cascade do |t|
    t.string   "description"
    t.datetime "due_date"
    t.integer  "member_id"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "channel_name"
    t.string   "command_text"
    t.string   "team_domain"
    t.string   "team_id"
    t.string   "slack_user_id"
    t.string   "slack_user_name"
    t.string   "slack_deferred_response_url"
    t.string   "channel_id"
    t.string   "assigned_member_id"
    t.datetime "assigned_due_date"
    t.string   "debug_trace"
    t.boolean  "done"
    t.string   "updated_by_slack_user_id"
    t.boolean  "archived",                    default: false
  end

  add_index "list_items", ["member_id"], name: "index_list_items_on_member_id", using: :btree

  create_table "members", force: :cascade do |t|
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "slack_user_id"
    t.integer  "team_id"
    t.string   "slack_team_id"
    t.string   "slack_user_name"
    t.string   "slack_user_real_name"
    t.string   "slack_team_name"
    t.string   "slack_user_api_token"
    t.string   "bot_api_token"
    t.string   "bot_user_id"
    t.string   "bot_dm_channel_id"
    t.string   "last_activity_type"
    t.datetime "last_activity_date"
    t.jsonb    "bot_msgs_json"
  end

  add_index "members", ["team_id"], name: "index_members_on_team_id", using: :btree

  create_table "omniauth_providers", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "uid"
    t.string   "auth_token"
    t.jsonb    "auth_json"
    t.jsonb    "auth_params_json"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "uid_email"
    t.string   "uid_name"
  end

  add_index "omniauth_providers", ["user_id"], name: "index_omniauth_providers_on_user_id", using: :btree

  create_table "posts", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "url"
    t.string   "slack_team_id"
    t.string   "api_token"
    t.string   "bot_user_id"
    t.string   "bot_access_token"
    t.jsonb    "members_hash"
    t.string   "slack_user_id"
  end

  add_index "teams", ["user_id"], name: "index_teams_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "role"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "channels", "teams"
  add_foreign_key "list_items", "members"
  add_foreign_key "members", "teams"
  add_foreign_key "omniauth_providers", "users"
  add_foreign_key "teams", "users"
end
