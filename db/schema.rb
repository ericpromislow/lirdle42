# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_11_16_222130) do

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chatrooms", force: :cascade do |t|
    t.boolean "is_lobby", default: false
    t.string "topic"
    t.string "slug"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "game_states", force: :cascade do |t|
    t.integer "state", default: 0
    t.string "candidateWords"
    t.string "finalWord"
    t.integer "wordIndex"
    t.integer "game_id"
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "pending_guess"
    t.index ["game_id"], name: "index_game_states_on_game_id"
    t.index ["user_id"], name: "index_game_states_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "chatroom_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["chatroom_id"], name: "index_games_on_chatroom_id"
  end

  create_table "guesses", force: :cascade do |t|
    t.string "word"
    t.string "score"
    t.integer "liePosition"
    t.integer "lieColor"
    t.string "marks"
    t.boolean "isCorrect"
    t.integer "guessNumber"
    t.integer "game_state_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["game_state_id"], name: "index_guesses_on_game_state_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.integer "from", null: false
    t.integer "to", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.integer "user_id"
    t.integer "chatroom_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["chatroom_id"], name: "index_messages_on_chatroom_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "theme"
    t.float "karma"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "password_digest"
    t.boolean "is_temporary", default: false
    t.integer "profile_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.integer "inactive_logins", default: 0
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.boolean "waiting_for_game", default: false
    t.integer "game_state_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["game_state_id"], name: "index_users_on_game_state_id"
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["waiting_for_game"], name: "index_users_on_waiting_for_game"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "game_states", "games"
  add_foreign_key "game_states", "users"
  add_foreign_key "games", "chatrooms"
  add_foreign_key "guesses", "game_states"
  add_foreign_key "messages", "chatrooms"
  add_foreign_key "messages", "users"
  add_foreign_key "users", "game_states"
end
