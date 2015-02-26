# encoding: UTF-8

class QuestsController < ApplicationController
  include ApplicationController::ImageInteractions
  include Filter::Builder

  before_filter :set_owner
  
  # GET /quests
  def index
    # init quest scope
    scope = if params[:owner_id] then User.find(params[:owner_id]).quests
            else                      Quest.active
            end
    
    # init location
    @location = Location.new(location_attrs)
    
    # set additional location scope
    scope = scope.nearby(@location.address, @location.radius) unless @location.unlimited?
    
    # set additional category scope
    @filters = filters_for(scope, :category)
    scope = scope.with_category(params[:category]) if params[:category].present?
    
    # fetch quests
    @quests = scope.paginate(
      :page       => params[:page] ||= 1,
      :per_page   => per_page,
      :group      => 'quests.id',
      :order      => "quests.created_at desc",
      :include    => [{ :owner => :identities }, :location, :comments, :offers])
  end

  # GET /quests/1
  def show
    # fetch the requested quest first
    # when current user is not known, it could be also a draft quest
    @quest = Quest.find_by_id(params[:id]) || Quest.draft(params[:id])

    return render :action => "preview" if params[:preview] # intending to be started (preview param is passed in this case)
  end

  def new
    @quest ||= Quest.new
    @quest.bounty_in_cents = Quest::DEFAULT_BOUNTY
    @quest.build_location(location_attrs)
  end

  def edit
    @quest = Quest.find(params[:id])

    # init location
    if @quest.location.present? then  @quest.restrict_location = true
    else                              @quest.build_location(location_attrs)
    end
    
    render :action => "new"
  end

  # POST /quests
  def create
    @quest = Quest.new(params[:quest])
    @quest.owner ||= User.draft
    
    # remove location if it's not given or not valid
    @quest.location = nil unless @quest.restrict_location?
    
    # Show start quest form after successful saving.
    if @quest.save
      flash[:success] = I18n.t("notice.create.success", :record => Quest.model_name.human)
      redirect_to! quest_path(@quest, :preview => true)
    end

    render :action => "new"
  end
  
  # PUT /quests/1
  def update
    @quest = Quest.find(params[:id])
    @quest.attributes = params[:quest]
    
    # remove location if user wants to
    unless @quest.restrict_location?
      @quest.location.mark_for_destruction if @quest.location.present?
    end
    
    if @quest.valid?
      @quest.save!
      flash[:success] = I18n.t("notice.update.success", :record => Quest.model_name.human)
      redirect_to! quest_path(@quest)
    end

    render :action => "new"
  end

  # DELETE /quests/1
  def destroy
    @quest = Quest.find(params[:id])
    @quest.destroy

    redirect_to quests_url
  end
  
private
  def set_owner
    @owner = User.find(params[:owner_id]) if params[:owner_id]
  end

  def location_attrs
    # when user filters by location, :location param is present
    return params[:location] if params[:location].present?

    # if user has a location as an address given we consider this one
    # otherwise we try to get the location from the current request
    address = if    current_user && current_user.location then  current_user.location
              elsif request && request.location           then  request.location.name
              end.to_s

    { :radius => 'unlimited', :address => address }
  end
end
