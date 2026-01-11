class BuilderController < ApplicationController
  def show
    @design_session = DesignSession.find_by!(uuid: params[:uuid])
  end
end
