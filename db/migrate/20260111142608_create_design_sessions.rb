class CreateDesignSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :design_sessions do |t|
      t.string :uuid, null: false
      t.string :product_type, null: false, default: "zipper_pouch"
      t.json :params_snapshot, null: false, default: {}
      t.string :name
      t.text :notes

      t.timestamps
    end

    add_index :design_sessions, :uuid, unique: true
  end
end
