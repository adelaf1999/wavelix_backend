# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_06_25_090636) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cart_items", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "quantity", null: false
    t.text "product_options"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "cart_id", null: false
    t.integer "store_user_id", null: false
  end

  create_table "carts", force: :cascade do |t|
    t.integer "customer_user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "store_user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "parent_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "author_id", null: false
    t.string "text", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "customer_users", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "date_of_birth", null: false
    t.string "gender", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "customer_id"
    t.text "home_address", null: false
    t.string "building_name"
    t.integer "apartment_floor"
    t.string "country", null: false
    t.string "default_currency", default: "USD"
    t.boolean "phone_number_verified", default: false
    t.string "phone_number"
  end

  create_table "days", force: :cascade do |t|
    t.string "week_day", null: false
    t.boolean "closed", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "schedule_id", null: false
    t.string "open_at_1"
    t.string "close_at_1"
    t.string "open_at_2"
    t.string "close_at_2"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "drivers", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "customer_user_id", null: false
    t.integer "status", default: 0
    t.string "currency", null: false
    t.decimal "balance", default: "0.0"
    t.boolean "driver_verified", default: false
    t.string "name", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.string "country", null: false
    t.index ["latitude", "longitude"], name: "index_drivers_on_latitude_and_longitude"
  end

  create_table "follows", force: :cascade do |t|
    t.integer "follower_id"
    t.integer "followed_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status", default: 1
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "likes", force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "liker_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "local_videos", force: :cascade do |t|
    t.text "video", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "orders", force: :cascade do |t|
    t.text "products", null: false, array: true
    t.integer "driver_id"
    t.integer "status", default: 1
    t.text "delivery_location", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "store_user_id", null: false
    t.integer "customer_user_id", null: false
    t.string "country", null: false
    t.decimal "delivery_fee"
    t.string "delivery_fee_currency", default: "USD"
    t.integer "order_type"
    t.integer "store_confirmation_status", default: 0
    t.boolean "store_handles_delivery", null: false
    t.time "store_arrival_time_limit"
    t.boolean "customer_canceled_order", default: false
    t.string "order_canceled_reason", default: ""
    t.string "driver_received_order_code"
    t.string "driver_fulfilled_order_code"
    t.boolean "store_fulfilled_order"
    t.boolean "driver_fulfilled_order"
    t.boolean "driver_arrived_to_store"
    t.boolean "driver_arrived_to_delivery_location"
    t.boolean "driver_canceled_order"
    t.decimal "total_price", null: false
    t.string "total_price_currency", default: "USD"
    t.integer "prospective_driver_id"
    t.datetime "delivery_time_limit"
    t.text "drivers_rejected", default: [], array: true
    t.text "unconfirmed_drivers", default: [], array: true
  end

  create_table "phone_numbers", force: :cascade do |t|
    t.string "number", null: false
    t.datetime "next_request_at", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "posts", force: :cascade do |t|
    t.integer "profile_id", null: false
    t.string "caption"
    t.integer "product_id"
    t.integer "media_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "image_file"
    t.text "video_file"
    t.integer "status", default: 0
    t.text "video_thumbnail"
    t.boolean "is_story", default: false
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "price", null: false
    t.text "main_picture", null: false
    t.boolean "product_available", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "category_id"
    t.text "product_attributes"
    t.text "product_pictures"
    t.string "store_country", null: false
    t.string "currency", null: false
    t.integer "stock_quantity"
    t.string "description", default: ""
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "privacy", default: 0
    t.text "profile_picture"
    t.string "profile_bio"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "schedules", force: :cascade do |t|
    t.integer "store_user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "store_users", force: :cascade do |t|
    t.string "store_owner_full_name", null: false
    t.string "store_owner_work_number", null: false
    t.string "store_name", null: false
    t.string "store_number", null: false
    t.string "store_country", null: false
    t.text "store_business_license", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "store_id"
    t.text "store_address", null: false
    t.integer "status", default: 0
    t.string "currency", null: false
    t.boolean "has_sensitive_products", default: false
    t.boolean "handles_delivery", default: false
    t.decimal "maximum_delivery_distance"
    t.decimal "balance", default: "0.0"
    t.string "street_name", default: ""
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "username"
    t.integer "user_type", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

end
