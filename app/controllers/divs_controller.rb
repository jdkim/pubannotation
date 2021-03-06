class DivsController < ApplicationController
  include ApplicationHelper
  
  # GET /pmcdocs/:pmcid/divs
  # GET /pmcdocs/:pmcid/divs.json
  def index
    @docs = Doc.find_all_by_sourcedb_and_sourceid('PMC', params[:pmcdoc_id], :order => 'serial ASC')

    if params[:project_id]
      @project_name = params[:project_id]
      @project = Project.find_by_name(@project_name)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @docs }
    end
  end
  
  def spans_index
    params[:div_id] = params[:id]
    if params[:project_id].present?
      @project, notice = get_project(params[:project_id])
      sourcedb, sourceid, serial = get_docspec(params)
      @doc, notice = get_doc(sourcedb, sourceid, serial, @project)
      if @doc
        annotations = get_annotations(@project, @doc, :encoding => params[:encoding])
        @denotations = annotations[:denotations]
      end
    else
      sourcedb, sourceid, serial = get_docspec(params)
      @doc, notice = get_doc(sourcedb, sourceid, serial, nil)
      if @doc
        # TODO uniq by begin-end?
        @denotations = @doc.denotations.order('begin ASC').collect {|ca| ca.get_hash}
      end
    end
    if @denotations.present?
      @denotations = @denotations.uniq{|denotation| denotation[:span]}
    end
    
    respond_to do |format|
      format.html { render 'docs/spans_index'}
    end
  end
  
  def spans
    if params[:project_id].present?
      @project, notice = get_project(params[:project_id])
      if @project
        @doc, flash[:notice] = get_doc('PMC', params[:pmcdoc_id], params[:id], @project)
      end
    else
      @doc, flash[:notice] = get_doc('PMC', params[:pmcdoc_id], params[:id])
      @projects = @doc.spans_projects(params)
    end
    @spans, @prev_text, @next_text = @doc.spans(params)
    @highlight_text = @doc.spans_highlight(params)
    respond_to do |format|
      format.html { render 'docs/spans'}
      format.txt  { render 'docs/spans'}
      format.json { render 'docs/spans'}
    end
  end
  
  def annotations
    if (params[:project_id])
      @project, notice = get_project(params[:project_id])
      @doc, flash[:notice] = get_doc('PMC', params[:pmcdoc_id], params[:id], @project)
    else
      @doc, flash[:notice] = get_doc('PMC', params[:pmcdoc_id], params[:id])
    end
    
    @spans, @prev_text, @next_text = @doc.spans(params)
    annotations = get_annotations(@project, @doc, :spans => {:begin_pos => params[:begin], :end_pos => params[:end]})
    annotations[:text] = @spans
    annotations[:spans] = {:begin => params[:begin], :end => params[:end]}
    annotations[:spans][:prev_text] = @prev_text if @prev_text.present?
    annotations[:spans][:next_text] = @next_text if @next_text.present?
    @denotations = annotations[:denotations]
    @instances = annotations[:instances]
    @relations = annotations[:relations]
    @modifications = annotations[:modifications]        

    respond_to do |format|
      format.html { render 'docs/annotations' }
      format.json { render :json => annotations, :callback => params[:callback]}
    end
  end

  # GET /pmcdocs/:pmcid/divs/:divid
  # GET /pmcdocs/:pmcid/divs/:divid.json
  def show
    if (params[:project_id])
      @project, notice = get_project(params[:project_id])
      if @project
        @doc, notice = get_doc('PMC', params[:pmcdoc_id], params[:id], @project)
        @annotations = get_annotations(@project, @doc)
      else
        @doc = nil
      end
    else
      @doc, notice = get_doc('PMC', params[:pmcdoc_id], params[:id])
      @projects = get_projects({:doc => @doc})
    end

    if @doc
      @text = @doc.body
      if (params[:encoding] == 'ascii')
        asciitext = get_ascii_text(@text)
        @text = asciitext
      end
    end

    respond_to do |format|
      if @doc
        format.html {
          flash[:notice] = notice
          render 'docs/show'
        }
        format.json {
          standoff = Hash.new
          standoff[:pmcdoc_id] = params[:pmcdoc_id]
          standoff[:div_id] = params[:id]
          standoff[:text] = @text
          render :json => standoff #, :callback => params[:callback]
        }
        format.txt  { render :text => @text }
      else 
        format.html { redirect_to pmcdocs_path, notice: notice}
        format.json { head :unprocessable_entity }
        format.txt  { head :unprocessable_entity }
      end
    end
  end

  # GET /pmcdocs/:pmcid/divs/new
  # GET /pmcdocs/:pmcid/divs/new.json
  def new
    @doc = Doc.new
    @doc.sourcedb = 'PMC'
    @doc.sourceid = params[:pmcdoc_id]
    @doc.source   = 'http://www.ncbi.nlm.nih.gov/pmc/' + params[:pmcdoc_id]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @doc }
    end
  end

  # GET /pmcdocs/:pmcid/divs/:divid/edit
  def edit
    # @doc = Doc.find(params[:id])
    @doc, notice = get_doc('PMC', params[:pmcdoc_id], params[:id])
  end

  # POST /pmcdocs/:pmcid/divs
  # POST /pmcdocs/:pmcid/divs.json
  def create
    @doc = Doc.new(params[:doc])
    @doc.sourcedb = 'PMC'
    @doc.sourceid = params[:pmcdoc_id]
    @doc.source = 'http://www.ncbi.nlm.nih.gov/pmc/' + @doc.sourceid
    @doc.serial   = params[:div_id]
    @doc.section  = params[:section]
    @doc.body     = params[:text]
    @doc.save

    if (params[:project_id])
      project = Project.find_by_name(params[:project_id])
      project.docs << @doc if project
    end

    respond_to do |format|
      unless @doc.new_record?
        format.html { redirect_to @doc, notice: t('controllers.shared.successfully_created', :model => t('activerecord.models.doc')) }
        format.json { head :no_content }
      else
        format.html { render action: "new" }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /docs/1
  # PUT /docs/1.json
  def update
    @doc = Doc.find(params[:id])

    respond_to do |format|
      if @doc.update_attributes(params[:doc])
        format.html { redirect_to @doc, notice: t('controllers.shared.successfully_updated', :model => t('activerecord.models.doc')) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /docs/1
  # DELETE /docs/1.json
  def destroy
    @doc = Doc.find(params[:id])
    @doc.destroy

    respond_to do |format|
      format.html { redirect_to docs_url }
      format.json { head :no_content }
    end
  end
end
