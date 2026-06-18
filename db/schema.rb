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

ActiveRecord::Schema[8.0].define(version: 2026_06_18_044802) do
  create_table "aliro_configs", force: :cascade do |t|
    t.integer "domain_id", null: false
    t.integer "created_by_id", null: false
    t.string "name", null: false
    t.string "reader_group_id", null: false
    t.string "reader_public_key", null: false
    t.string "reader_certificate"
    t.boolean "is_sample", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_aliro_configs_on_created_by_id"
    t.index ["domain_id", "is_sample"], name: "index_aliro_configs_on_domain_id_and_is_sample"
    t.index ["domain_id"], name: "index_aliro_configs_on_domain_id"
  end

  create_table "domains", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_domains_on_name", unique: true
  end

  create_table "one_time_shares", force: :cascade do |t|
    t.string "token", null: false
    t.integer "aliro_config_id"
    t.string "secret_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "retrieved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aliro_config_id"], name: "index_one_time_shares_on_aliro_config_id"
    t.index ["token"], name: "index_one_time_shares_on_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "aliro_configs", "domains"
  add_foreign_key "aliro_configs", "users", column: "created_by_id"
  add_foreign_key "one_time_shares", "aliro_configs", on_delete: :nullify
end
