module Patterns
  class GeometryEngine
    def initialize(assembly_definition:, params:)
      @assembly_definition = assembly_definition
      @params = params || {}
    end

    def call
      {
        assembly_key: @assembly_definition&.key,
        params: @params,
        preview_3d: definition["preview_3d"],
        panels: build_panels,
        seams: Array(definition["seams"]),
        steps: Array(definition["steps"])
      }
    end

    private

    def definition
      @definition ||= (@assembly_definition&.definition_json || {})
    end

    def build_panels
      Array(definition["panels"]).map do |panel|
        width = numeric_param(panel["width_param"])
        height = numeric_param(panel["height_param"])

        {
          key: panel["key"],
          label: panel["label"],
          width: width,
          height: height,
          path: rectangle_path(width, height)
        }
      end
    end

    def numeric_param(key)
      return 0.0 if key.nil?

      raw = @params[key.to_s] || @params[key.to_sym]
      return 0.0 if raw.nil? || raw == ""

      raw.to_f
    end

    def rectangle_path(width, height)
      [
        { x: 0.0, y: 0.0 },
        { x: width, y: 0.0 },
        { x: width, y: height },
        { x: 0.0, y: height }
      ]
    end
  end
end
