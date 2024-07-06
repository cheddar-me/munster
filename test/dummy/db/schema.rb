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

ActiveRecord::Schema[7.1].define(version: 2024_07_05_180333) do
  create_table "received_webhooks", force: :cascade do |t|
    t.string "handler_event_id", null: false
    t.string "handler_module_name", null: false
    t.string "status", default: "received", null: false
    t.binary "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "request_headers"
    t.index ["handler_module_name", "handler_event_id"], name: "webhook_dedup_idx", unique: true
    t.index ["status"], name: "index_received_webhooks_on_status"
  end
end
