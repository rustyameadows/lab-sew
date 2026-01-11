class ProjectsController < ApplicationController
  def index
    @design_sessions = DesignSession.order(updated_at: :desc)
  end

  def create
    design_session = DesignSession.create!(product_type: "zipper_pouch")
    redirect_to project_builder_path(design_session.uuid)
  end

  def destroy
    design_session = DesignSession.find_by!(uuid: params[:uuid])
    design_session.destroy!
    redirect_to projects_path
  end
end
