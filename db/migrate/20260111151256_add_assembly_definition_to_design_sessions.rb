class AddAssemblyDefinitionToDesignSessions < ActiveRecord::Migration[8.0]
  def change
    add_reference :design_sessions, :assembly_definition, foreign_key: true
  end
end
