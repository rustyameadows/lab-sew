class AssemblyDefinition < ApplicationRecord
  has_many :design_sessions, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  def self.seed_defaults
    zipper = find_or_initialize_by(key: "zipper_pouch")
    zipper.assign_attributes(
      name: "Zipper pouch",
      version: 1,
      definition_json: zipper_pouch_definition
    )
    zipper.save!

    tote = find_or_initialize_by(key: "tote_bag")
    tote.assign_attributes(
      name: "Tote bag",
      version: 1,
      definition_json: tote_bag_definition
    )
    tote.save!

    [zipper, tote]
  end

  def self.default
    seed_defaults
    find_by!(key: "zipper_pouch")
  end

  def self.zipper_pouch_definition
    {
      parameters: [
        { key: "height", label: "Height", type: "number", default: 9, group: "Measurements" },
        { key: "width", label: "Width", type: "number", default: 11, group: "Measurements" },
        { key: "depth", label: "Depth", type: "number", default: 1.5, group: "Measurements" },
        { key: "seam_allowance", label: "Seam allowance", type: "number", default: 0.25, group: "Measurements" },
        {
          key: "zipper_locations",
          label: "Zipper location",
          type: "multiselect",
          default: ["top"],
          group: "Zipper",
          options: [
            { value: "top", label: "Top" },
            { value: "left", label: "Left" },
            { value: "right", label: "Right" },
            { value: "bottom", label: "Bottom" }
          ]
        },
        {
          key: "zipper_style",
          label: "Zipper style",
          type: "select",
          default: "standard",
          group: "Zipper",
          options: [
            { value: "standard", label: "Standard" },
            { value: "exposed", label: "Exposed" }
          ]
        },
        { key: "pocket_enabled", label: "Enable pocket", type: "checkbox", default: false, group: "Pocket" },
        {
          key: "pocket_placement",
          label: "Placement",
          type: "select",
          default: "center",
          group: "Pocket",
          options: [
            { value: "top", label: "Top" },
            { value: "center", label: "Center" },
            { value: "bottom", label: "Bottom" }
          ]
        }
      ],
      panels: [
        { key: "front", label: "Front", width_param: "width", height_param: "height" },
        { key: "back", label: "Back", width_param: "width", height_param: "height" },
        { key: "gusset", label: "Gusset", width_param: "width", height_param: "depth" },
        { key: "zipper_panel", label: "Zipper panel", width_param: "width", height_param: "depth" }
      ],
      seams: [],
      steps: []
    }
  end

  def self.tote_bag_definition
    {
      parameters: [
        { key: "body_height", label: "Body height", type: "number", default: 14, group: "Body" },
        { key: "body_width", label: "Body width", type: "number", default: 16, group: "Body" },
        { key: "base_depth", label: "Base depth", type: "number", default: 4, group: "Body" },
        { key: "strap_length", label: "Strap length", type: "number", default: 24, group: "Straps" },
        { key: "strap_width", label: "Strap width", type: "number", default: 1.5, group: "Straps" }
      ],
      panels: [
        { key: "front", label: "Front", width_param: "body_width", height_param: "body_height" },
        { key: "back", label: "Back", width_param: "body_width", height_param: "body_height" },
        { key: "side_gusset", label: "Side gusset", width_param: "base_depth", height_param: "body_height" },
        { key: "base", label: "Base", width_param: "body_width", height_param: "base_depth" },
        { key: "strap", label: "Strap", width_param: "strap_length", height_param: "strap_width" }
      ],
      seams: [],
      steps: []
    }
  end

  def parameter_defaults
    Array(definition_json["parameters"]).each_with_object({}) do |param, acc|
      acc[param["key"]] = param["default"] if param.key?("default")
    end
  end
end
