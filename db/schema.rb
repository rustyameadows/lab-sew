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

ActiveRecord::Schema[8.0].define(version: 2026_01_11_153300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assembly_definitions", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.integer "version", default: 1, null: false
    t.json "definition_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_assembly_definitions_on_key", unique: true
  end

  create_table "design_sessions", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "product_type", default: "zipper_pouch", null: false
    t.json "params_snapshot", default: {}, null: false
    t.string "name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "assembly_definition_id"
    t.index ["assembly_definition_id"], name: "index_design_sessions_on_assembly_definition_id"
    t.index ["uuid"], name: "index_design_sessions_on_uuid", unique: true
  end

  add_foreign_key "design_sessions", "assembly_definitions"
end
