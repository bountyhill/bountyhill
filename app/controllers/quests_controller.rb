class QuestsController < ApplicationController
  include ApplicationController::ImageParameters
  
  # GET /quests
  # GET /quests.json
  def index
    @quests = Quest.paginate(:page => params[:page], :per_page => per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @quests }
    end
  end

  # GET /quests/1
  # GET /quests/1.json
  def show
    @quest = Quest.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @quest }
    end
  end

  # GET /quests/new
  # GET /quests/new.json
  def new
    @quest = Quest.new

    # fill in location, if the server provides one.
    @quest.location = location.name if location = request.location
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @quest }
    end
  end

  # GET /quests/1/edit
  def edit
    @quest = Quest.find(params[:id])
  end


  # POST /quests
  # POST /quests.json
  def create
    params[:quest][:image] = image_param
    @quest = Quest.new(params[:quest])

    # (Try to) save
    respond_to do |format|
      if @quest.valid?
        @quest.save!
        
        format.html { redirect_to @quest, notice: 'Quest was successfully created.' }
        format.json { render json: @quest, status: :created, location: @quest }
      else
        format.html { render action: "new" }
        format.json { render json: @quest.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /quests/1
  # PUT /quests/1.json
  def update
    @quest = Quest.find(params[:id])

    respond_to do |format|
      if @quest.valid?
        @quest.update_attributes(params[:quest])
        
        format.html { redirect_to quests_path, notice: 'Quest was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @quest.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /quests/1
  # DELETE /quests/1.json
  def destroy
    @quest = Quest.find(params[:id])
    @quest.destroy

    respond_to do |format|
      format.html { redirect_to quests_url }
      format.json { head :no_content }
    end
  end
end
