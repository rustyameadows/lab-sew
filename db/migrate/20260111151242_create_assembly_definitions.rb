class CreateAssemblyDefinitions < ActiveRecord::Migration[8.0]
  def change
    create_table :assembly_definitions do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.integer :version, null: false, default: 1
      t.json :definition_json, null: false, default: {}

      t.timestamps
    end

    add_index :assembly_definitions, :key, unique: true
  end
end
