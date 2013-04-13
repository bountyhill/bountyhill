class QuestsController < ApplicationController
  include ApplicationController::ImageInteractions
  include Filter::Builder
  
  # GET /quests
  def index
    scope = if params[:owner_id] then User.find(params[:owner_id]).quests
            else                      Quest.for_current_user # active or (pending and owned by current user pending)
            end

    @filters = filters_for(scope, :category)
    
    scope = scope.with_category(params[:category]) if params[:category]

    @quests = scope.paginate(
      :page       => params[:page],
      :per_page   => per_page,
      :order      => "quests.created_at desc",
      :include    => { :owner => :identities })
  end

  # GET /quests/1
  def show
    @quest = Quest.find(params[:id])

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
    
    # Start the quest after saving.
    if @quest.save
      redirect_to! quest_path(@quest, :preview => true), :notice => 'Quest was successfully created.'
    end

    render :action => "new"
  end
  
  # PUT /quests/1
  def update
    @quest = Quest.find(params[:id])
    @quest.attributes = params[:quest]

    if @quest.location && @quest.restrict_location.blank?
      @quest.location.mark_for_destruction
    end

    if @quest.valid?
      @quest.save!
      redirect_to! quest_path(@quest), :notice => 'Quest was successfully updated.'
    end

    render :action => "new"
  end

  # DELETE /quests/1
  def destroy
    @quest = Quest.find(params[:id])
    @quest.destroy

    redirect_to quests_url
  end
end
