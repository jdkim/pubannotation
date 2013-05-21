class ProjectsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]

  # GET /projects
  # GET /projects.json
  def index
    sourcedb, sourceid, serial = get_docspec(params)
    if sourcedb
      @doc = Doc.find_by_sourcedb_and_sourceid_and_serial(sourcedb, sourceid, serial)
      if @doc
        @projects = get_projects(@doc)
      else
        @projects = nil
        notice = "The document, #{sourcedb}:#{sourceid}, does not exist in PubAnnotation."
      end
    else
      @projects = get_projects()
    end

    respond_to do |format|
      format.html {
        if @doc and @projects == nil
          redirect_to home_path, :notice => notice
        end
      }
      format.json { render json: @projects }
    end
  end

  # GET /projects/:name
  # GET /projects/:name.json
  def show
    @project, notice = get_project(params[:id])
    if @project
      sourcedb, sourceid, serial = get_docspec(params)
      if sourceid
        @doc, notice = get_doc(sourcedb, sourceid, serial, @project)
      else
        docs = @project.docs
        @pmdocs_num = docs.select{|d| d.sourcedb == 'PubMed'}.length
        @pmcdocs_num = docs.select{|d| d.sourcedb == 'PMC' and d.serial == 0}.length
      end
    end

    respond_to do |format|
      if @project
        format.html { flash[:notice] = notice }
        format.json { render json: @project }
      else
        format.html {
          redirect_to home_path, :notice => notice
        }
        format.json { head :unprocessable_entity }
      end
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @sourcedb, @sourceid, @serial = get_docspec(params)
    @project = Project.find_by_name(params[:id])
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(params[:project])
    @project.user = current_user
    
    respond_to do |format|
      if @project.save
        format.html { redirect_to project_path(@project.name), :notice => 'Annotation set was successfully created.' }
        format.json { render json: @project, status: :created, location: @project }
      else
        format.html { render action: "new" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/:name
  # PUT /projects/:name.json
  def update
    @project = Project.find(params[:id])

    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to project_path(@project.name), :notice => 'Annotation set was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/:name
  # DELETE /projects/:name.json
  def destroy
    @project = Project.find_by_name(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_path, notice: "The annotation set, #{params[:id]}, was deleted." }
      format.json { head :no_content }
    end
  end
end