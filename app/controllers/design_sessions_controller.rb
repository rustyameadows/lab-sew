require Rails.root.join("app/services/patterns/geometry_engine").to_s

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
