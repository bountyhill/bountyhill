class OffersController < ApplicationController
  include ApplicationController::ImageParameters
  
  public
  
  # GET /quests
  # GET /quests.json
  def index
    @offers = Offer.paginate(:page => params[:page], :per_page => per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @offers }
    end
  end

  # GET /quests/1
  # GET /quests/1.json
  def show
    @offer = Offer.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @offer }
    end
  end

  # GET /quests/new
  # GET /quests/new.json
  def new
    @offer = Offer.new(:quest_id => params[:quest_id])
    
    # fill in location, if the server provides one.
    if location = request.location
      @offer.location = location.name
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @offer }
    end
  end

  # GET /quests/1/edit
  def edit
    @offer = Offer.find(params[:id])
  end

  # POST /quests
  # POST /quests.json
  def create
    params[:offer][:image] = image_param
    
    @offer = Offer.new(params[:offer])

    # (Try to) save
    respond_to do |format|
      if @offer.valid?
        @offer.save!
        
        format.html { redirect_to @offer, notice: 'Quest was successfully created.' }
        format.json { render json: @offer, status: :created, location: @offer }
      else
        # raise @offer.errors.inspect
        
        format.html { render action: "new" }
        format.json { render json: @offer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /quests/1
  # PUT /quests/1.json
  def update
    @offer = Offer.find(params[:id])

    respond_to do |format|
      if @offer.valid?
        @offer.update_attributes(params[:offer])
        
        format.html { redirect_to quests_path, notice: 'Quest was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @offer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /quests/1
  # DELETE /quests/1.json
  def destroy
    @offer = Offer.find(params[:id])
    @offer.destroy

    respond_to do |format|
      format.html { redirect_to quests_url }
      format.json { head :no_content }
    end
  end
end
