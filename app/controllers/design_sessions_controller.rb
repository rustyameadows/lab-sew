class DesignSessionsController < ApplicationController
  protect_from_forgery with: :null_session

  def show
    design_session = DesignSession.find_by!(uuid: params[:uuid])
    render json: serialize(design_session)
  end

  def create
    design_session = DesignSession.new(design_session_params)
    design_session.params_snapshot = default_params if design_session.params_snapshot.blank?

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

  private

  def design_session_params
    params.fetch(:design_session, {}).permit(
      :name,
      :product_type,
      :notes,
      params_snapshot: {}
    )
  end

  def default_params
    {
      units: "in",
      height: 9.0,
      width: 11.0,
      depth: 1.5,
      seam_allowance: 0.25,
      zipper_location: "top",
      zipper_style: "standard",
      pocket: {
        enabled: false,
        placement: "center"
      }
    }
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
