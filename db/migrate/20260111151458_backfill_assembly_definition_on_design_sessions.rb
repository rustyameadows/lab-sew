class BackfillAssemblyDefinitionOnDesignSessions < ActiveRecord::Migration[8.0]
  def up
    return unless table_exists?(:assembly_definitions) && table_exists?(:design_sessions)

    default_definition = AssemblyDefinition.default
    DesignSession.where(assembly_definition_id: nil).update_all(assembly_definition_id: default_definition.id)
  end

  def down
    return unless table_exists?(:design_sessions)

    DesignSession.update_all(assembly_definition_id: nil)
  end
end
