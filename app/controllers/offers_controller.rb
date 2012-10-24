class OffersController < ApplicationController
  include ApplicationController::ImageParameters
  
  public
  
  # GET /quests
  def index
    scope = Offer.order("offers.created_at DESC")
    if params[:quest_id]
      scope = scope.where(:quest_id => params[:quest_id]).order("offers.compliance DESC, offers.created_at DESC")
    end
    if params[:owner_id]
      # relevant_for: owned by user or sent to user
      scope = scope.relevant_for(User.find(params[:owner_id]))
    end
    
    @offers = scope.paginate(:include => :quest, :page => params[:page], :per_page => per_page)
  end

  # GET /offers/1
  def show
    @offer = Offer.find(params[:id])
  end

  # GET /offers/new
  def new
    request_identity! :confirmed 
    @offer = Offer.new(:quest_id => params[:quest_id])
    
    # fill in location, if the server provides one.
    if location = request.location
      @offer.location = location.name
    end
  end

  # GET /offers/1/edit
  def edit
    @offer = Offer.find(params[:id])
    render action: "new"
  end

  # POST /quests
  def create
    @offer = Offer.new(params[:offer])

    # (Try to) save
    if @offer.valid?
      @offer.save!
      
      redirect_to @offer, notice: 'Offer was successfully created.'
    else
      render action: "new"
    end
  end

  # PUT /offers/1
  def update
    @offer = Offer.find(params[:id])

    if @offer.valid?
      @offer.update_attributes(params[:offer])
      
      redirect_to quests_path, notice: 'The offer was successfully updated.'
    else
      render action: "edit"
    end
  end

  # DELETE /offers/1
  def destroy
    @offer = Offer.find(params[:id])
    @offer.destroy

    redirect_to quests_url
  end
  
  # Withdraw the offer
  def withdraw
    @offer = Offer.find(params[:id])
    if @offer.owner == current_user
      @offer.withdraw!
    end
    
    redirect_to @offer.quest
  end

  # Accept the offer
  def accept
    @offer = Offer.find(params[:id])
    if @offer.quest.owner == current_user
      @offer.accept!
    end
    
    redirect_to @offer.quest
  end

  # Decline the offer
  def decline
    @offer = Offer.find(params[:id])
    if @offer.quest.owner == current_user
      @offer.decline! 
    end
    
    redirect_to @offer.quest
  end
end
