class AssemblyDefinition < ApplicationRecord
  has_many :design_sessions, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  def self.default
    find_or_create_by!(key: "zipper_pouch") do |definition|
      definition.name = "Zipper pouch"
      definition.version = 1
      definition.definition_json = {
        panels: [],
        seams: [],
        steps: []
      }
    end
  end
end
