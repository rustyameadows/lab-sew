class AssemblyDefinitionsController < ApplicationController
  def index
    @assemblies = AssemblyDefinition.order(:name)
  end

  def new
    @assembly = AssemblyDefinition.new(definition_json: default_definition_json)
  end

  def create
    @assembly = AssemblyDefinition.new
    assign_attributes(@assembly)

    if @assembly.save
      redirect_to assemblies_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @assembly = AssemblyDefinition.find(params[:id])
  end

  def update
    @assembly = AssemblyDefinition.find(params[:id])
    assign_attributes(@assembly)

    if @assembly.save
      redirect_to assemblies_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def assign_attributes(assembly)
    assembly.assign_attributes(assembly_params.except(:definition_json))
    assembly.definition_json = parse_definition_json
  end

  def assembly_params
    params.require(:assembly_definition).permit(:key, :name, :version, :definition_json)
  end

  def parse_definition_json
    raw = assembly_params[:definition_json].presence || "{}"
    JSON.parse(raw)
  rescue JSON::ParserError
    {}
  end

  def default_definition_json
    {
      panels: [],
      seams: [],
      steps: []
    }
  end
end
