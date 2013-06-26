class OffersController < ApplicationController
  include ApplicationController::ImageInteractions
  include Filter::Builder

  layout false, :only => [:accept, :reject, :withdraw]
  
  # GET /offers
  def index
    scope = Offer
    order = "offers.created_at DESC"
    
    if params[:quest_id]
      scope = scope.where(:quest_id => params[:quest_id])
      order = "offers.compliance DESC, offers.created_at DESC"
    end
    
    # relevant_for: owned by user or sent to user
    scope = scope.relevant_for(User.find(params[:owner_id])) if params[:owner_id]
    
    # set additional state scope
    @filters = filters_for(scope, :state)
    scope = scope.with_state(params[:state]) if params[:state]

    @offers = scope.paginate(
      :page     => params[:page],
      :per_page => per_page,
      :order    => order)
  end

  # GET /offers/1
  def show
    @offer = Offer.find(params[:id])

    unless @offer.viewed_at.present? || current_user.owns?(@offer)
      @offer.update_attribute(:viewed_at, Time.now)
    end
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
    @offer = Offer.find(params[:id], :readonly => false)
    render :action => "new"
  end

  # POST /quests
  def create
    @offer = Offer.new(params[:offer])

    if @offer.save
      redirect_to @offer, :notice => I18n.t("message.create.success", :record => Offer.model_name.human)
    else
      render action: "new"
    end
  end

  # PUT /offers/1
  def update
    @offer = Offer.find(params[:id], :readonly => false)

    if @offer.valid?
      @offer.update_attributes(params[:offer])
      
      redirect_to quests_path, :notice => I18n.t("message.update.success", :record => Offer.model_name.human)
    else
      render :action => "edit"
    end
  end

  # DELETE /offers/1
  def destroy
    @offer = Offer.find(params[:id], :readonly => false)
    @offer.destroy

    redirect_to quests_url
  end
  
  # Withdraw the offer
  def withdraw
    @offer = Offer.find(params[:id], :readonly => false)
    
    unless request.get?
      @offer.withdraw! if current_user.owns?(@offer)
      redirect_to @offer.quest
    end
  end

  # Accept the offer
  def accept
    @offer = Offer.find(params[:id], :readonly => false)

    unless request.get?
      @offer.accept! if current_user.owns?(@offer.quest)
      redirect_to @offer.quest
    end
  end

  # Reject the offer
  def reject
    @offer = Offer.find(params[:id],:readonly => false)

    unless request.get?
      @offer.reject! if current_user.owns?(@offer.quest)
      redirect_to @offer.quest
    end
  end
end
