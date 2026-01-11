class BuilderController < ApplicationController
  def show
    @design_session = DesignSession.find_by!(uuid: params[:uuid])
    @assemblies = AssemblyDefinition.order(:name)
  end
end
