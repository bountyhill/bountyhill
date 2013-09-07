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
    
    # set additional location scope
    @location = request.location
    scope = scope.nearby(@location.name, params[:radius]) if params[:radius].present?
    
    # set additional category scope
    @filters = filters_for(scope, :category)
    scope = scope.with_category(params[:category]) if params[:category].present?
    
    # fetch quests
    @quests = scope.paginate(
      :page       => params[:page],
      :per_page   => per_page,
      :order      => "quests.created_at desc",
      :include    => [{ :owner => :identities }, :location])
  end

  # GET /quests/1
  def show
    # fetch the requested quest first
    # when current user is not known, it could be also a draft quest
    @quest = Quest.find_by_id(params[:id]) || Quest.draft(params[:id])

    # intending to be started (preview param is passed in this case)
    render :action => "preview" if params[:preview]
  end

  def new
    @quest ||= Quest.new
    @quest.bounty_in_cents = Quest::DEFAULT_BOUNTY
    @quest.build_location(:location => request.location)
  end

  def edit
    @quest = Quest.find(params[:id])
    @quest.build_location unless @quest.location.present?
    
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
      redirect_to! quest_path(@quest, :preview => true), :notice => I18n.t("message.create.success", :record => Quest.model_name.human)
    end

    render :action => "new"
  end
  
  # PUT /quests/1
  def update
    @quest = Quest.find(params[:id], :readonly => false)
    @quest.attributes = params[:quest]
    
    # remove location if user wants to
    unless @quest.restrict_location?
      @quest.location.mark_for_destruction if @quest.location.present?
    end
    
    if @quest.valid?
      @quest.save!
      redirect_to! quest_path(@quest), :notice => 'Quest was successfully updated.'
    end

    render :action => "new"
  end

  # DELETE /quests/1
  def destroy
    @quest = Quest.find(params[:id], :readonly => false)
    @quest.destroy

    redirect_to quests_url
  end
  
private
  def set_owner
    @owner = User.find(params[:owner_id], :readonly => true) if params[:owner_id]
  end

end
