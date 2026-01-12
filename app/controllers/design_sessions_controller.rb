class DesignSessionsController < ApplicationController
  protect_from_forgery with: :null_session

  def show
    design_session = DesignSession.find_by!(uuid: params[:uuid])
    render json: serialize(design_session)
  end

  def create
    design_session = DesignSession.new(design_session_params)

    if design_session.save
      render json: serialize(design_session), status: :created
    else
      render json: { errors: design_session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    design_session = DesignSession.find_by!(uuid: params[:uuid])

    if design_session.update(design_session_params)
      render json: serialize(design_session)
    else
      render json: { errors: design_session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def geometry
    design_session = DesignSession.find_by!(uuid: params[:uuid])
    assembly = design_session.assembly_definition

    unless assembly
      render json: { error: "Assembly not set for this project." }, status: :unprocessable_entity
      return
    end

    defaults = assembly.parameter_defaults
    params_snapshot = (design_session.params_snapshot || {}).deep_stringify_keys
    effective_params = defaults.merge(params_snapshot)

    geometry = Patterns::GeometryEngine.new(assembly_definition: assembly, params: effective_params).call
    render json: geometry
  end

  def preview
    design_session = DesignSession.find_by!(uuid: params[:uuid])
    assembly = design_session.assembly_definition

    unless assembly
      render plain: "Assembly not set", status: :unprocessable_entity
      return
    end

    defaults = assembly.parameter_defaults
    params_snapshot = (design_session.params_snapshot || {}).deep_stringify_keys
    effective_params = defaults.merge(params_snapshot)

    geometry = Patterns::GeometryEngine.new(assembly_definition: assembly, params: effective_params).call

    if params[:panel].present?
      panels = Array(geometry[:panels] || geometry["panels"]).select do |panel|
        panel_key = panel[:key] || panel["key"]
        panel_key.to_s == params[:panel].to_s
      end
      geometry = geometry.merge(panels: panels)
    end

    scale = params[:scale].to_f
    scale = 24.0 unless scale.positive?

    svg = Patterns::SvgRenderer.new(geometry, scale: scale).call
    svg = svg.gsub(/<text\b[^>]*>.*?<\/text>/m, "") if params[:panel].present?
    svg = svg.gsub(/rx="[^"]*"/, 'rx="0"').gsub(/ry="[^"]*"/, 'ry="0"')

    render plain: svg, content_type: "image/svg+xml"
  end

  private

  def design_session_params
    params.fetch(:design_session, {}).permit(
      :name,
      :product_type,
      :assembly_definition_id,
      :notes,
      params_snapshot: {}
    )
  end

  def serialize(design_session)
    {
      uuid: design_session.uuid,
      name: design_session.name,
      product_type: design_session.product_type,
      params_snapshot: design_session.params_snapshot,
      notes: design_session.notes,
      created_at: design_session.created_at,
      updated_at: design_session.updated_at
    }
  end
end
