class SeedDefaultAssemblies < ActiveRecord::Migration[8.0]
  def up
    return unless table_exists?(:assembly_definitions)

    AssemblyDefinition.seed_defaults
  end

  def down
    return unless table_exists?(:assembly_definitions)

    AssemblyDefinition.where(key: %w[zipper_pouch tote_bag]).delete_all
  end
end
