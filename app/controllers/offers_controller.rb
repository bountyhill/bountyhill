# encoding: UTF-8

class OffersController < ApplicationController
  include ApplicationController::ImageInteractions
  include Filter::Builder

  before_filter :init_offer, :except => [:index, :new, :create]
  before_filter :set_owner

  layout false, :only => [:activate, :accept, :reject, :withdraw]
  
  # GET /offers
  def index
    scope = Offer
    order = "offers.created_at DESC"
    
    if params[:quest_id]
      scope = scope.where(:quest_id => params[:quest_id])
      order = "offers.compliance DESC, offers.created_at DESC"
    end
    
    conditions = if params[:owner_id] then { :owner_id => @owner.id }
                 else                      { :quest_id => @owner.quest_ids, :state => Offer::STATES-['new'] }
                 end
    scope = scope.where(conditions)
    
    # set additional state scope
    @filters = filters_for(scope, :state)
    scope = scope.with_state(params[:state]) if params[:state]

    @offers = scope.paginate(
      :page     => params[:page] ||= 1,
      :per_page => per_page,
      :group    => 'offers.id',
      :order    => order)
  end

  # GET /offers/1
  def show
    @offer.viewed!
    
    render :action => "preview" if params[:preview]
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
    render :action => "new"
  end

  # POST /quests
  def create
    @offer = Offer.new(params[:offer])

    # Activate the offer after saving.
    if @offer.save
      flash[:success] = I18n.t("message.create.success", :record => Offer.model_name.human)
      redirect_to! offer_path(@offer, :preview => true)
    end
    
    render :action => "new"
  end

  # PUT /offers/1
  def update
    if @offer.update_attributes(params[:offer])
      flash[:success] = I18n.t("message.update.success", :record => Offer.model_name.human)
      redirect_to offer_path(@offer)
    else
      render :action => "new"
    end
  end

  # DELETE /offers/1
  def destroy
    @offer.destroy
    flash[:success] = I18n.t("message.destroy.success", :record => Offer.model_name.human)
    redirect_to offers_url(:owner => current_user)
  end
  
  # Submit he offer
  def activate
    unless request.get?
      @offer.activate!
      flash[:success] = I18n.t("offer.action.activate", :offer => @offer.title)
      redirect_to! @offer
    end
  end
  
  # Withdraw the offer
  def withdraw
    unless request.get?
      @offer.withdraw!(params[:offer])
      flash[:success] = I18n.t("offer.action.withdraw", :offer => @offer.title)
      redirect_to! @offer
    end
  end

  # Accept the offer
  def accept
    unless request.get?
      @offer.accept!(params[:offer])
      flash[:success] = I18n.t("offer.action.accept", :offer => @offer.title)
      redirect_to! @offer
    end
  end

  # Reject the offer
  def reject
    unless request.get?
      @offer.reject!(params[:offer])
      flash[:success] = I18n.t("offer.action.reject", :offer => @offer.title)
      redirect_to! @offer
    end
  end
  
private
  def init_offer
    @offer = Offer.find(params[:id])
  end

  def set_owner
    @owner = if params[:owner_id]
      User.find(params[:owner_id])
    else
      current_user
    end
    
    false unless @owner && (@owner == current_user || @owner.admin?)
  end
  
end
