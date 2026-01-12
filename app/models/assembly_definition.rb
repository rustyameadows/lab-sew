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
        { key: "left_side", label: "Left side", width_param: "depth", height_param: "height" },
        { key: "right_side", label: "Right side", width_param: "depth", height_param: "height" },
        { key: "bottom", label: "Bottom", width_param: "width", height_param: "depth" },
        { key: "zipper_panel", label: "Zipper panel", width_param: "width", height_param: "depth" }
      ],
      preview_3d: {
        layout: "box",
        width_param: "width",
        height_param: "height",
        depth_param: "depth",
        root: "front",
        panels: {
          front: { role: "front" },
          back: { role: "back" },
          left_side: { role: "side_left" },
          right_side: { role: "side" },
          bottom: { role: "bottom" },
          zipper_panel: { role: "top" }
        },
        seams: [
          { parent: "front", parent_edge: "right", child: "right_side", child_edge: "left", angle: 90 },
          { parent: "front", parent_edge: "left", child: "left_side", child_edge: "right", angle: -90 },
          { parent: "front", parent_edge: "bottom", child: "bottom", child_edge: "top", angle: -90 },
          { parent: "front", parent_edge: "top", child: "zipper_panel", child_edge: "bottom", angle: 90 },
          { parent: "right_side", parent_edge: "right", child: "back", child_edge: "left", angle: 90 }
        ]
      },
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
        { key: "side_left", label: "Side left", width_param: "base_depth", height_param: "body_height" },
        { key: "side_right", label: "Side right", width_param: "base_depth", height_param: "body_height" },
        { key: "base", label: "Base", width_param: "body_width", height_param: "base_depth" },
        { key: "strap", label: "Strap", width_param: "strap_length", height_param: "strap_width" }
      ],
      preview_3d: {
        layout: "open_box",
        width_param: "body_width",
        height_param: "body_height",
        depth_param: "base_depth",
        root: "front",
        panels: {
          front: { role: "front" },
          back: { role: "back" },
          side_left: { role: "side_left" },
          side_right: { role: "side" },
          base: { role: "bottom" },
          strap: { role: "strap" }
        },
        seams: [
          { parent: "front", parent_edge: "right", child: "side_right", child_edge: "left", angle: 90 },
          { parent: "front", parent_edge: "left", child: "side_left", child_edge: "right", angle: -90 },
          { parent: "front", parent_edge: "bottom", child: "base", child_edge: "top", angle: -90 },
          { parent: "side_right", parent_edge: "right", child: "back", child_edge: "left", angle: 90 },
          { parent: "side_left", parent_edge: "left", child: "back", child_edge: "right", angle: -90 }
        ]
      },
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
