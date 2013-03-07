class QuestsController < ApplicationController
  include ApplicationController::ImageInteractions
  layout false, :only => [:new, :edit]
  
  # GET /quests
  def index
    scope = if params[:owner_id] then Quest
            else                      Quest.personal # active or (pending and owned by current user pending)
            end

    conditions = {}

    conditions[:owner_id] = params[:owner_id] if params[:owner_id].present?
    @filters = Filter.filters_for(Quest, :category, scope, conditions).sort_by{ |f| I18n.t(f.name, :scope => "quest.categories") }

    conditions[:category] = params[:category] if params[:category].present?
    @quests = scope.paginate(
      :page       => params[:page],
      :per_page   => per_page,
      :order      => "quests.created_at desc",
      :conditions => conditions,
      :include    => { :owner => :identities })
      
    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /quests/1
  def show
    @quest = Quest.find(params[:id])
  end

  def new
    @quest ||= Quest.new

    # When we come from the start page, we might have a quest title.
    @quest.title = params[:q]
    
    # fill in location, if the server provides one.
    if location = request.location
      @quest.location = location.name 
    end
  end

  def edit
    @quest = Quest.find(params[:id])
    render action: "new"
  end

  # POST /quests
  def create
    @quest = Quest.new(params[:quest])
    @quest.owner ||= User.draft
    @quest.bounty_in_cents ||= Quest::DEFAULT_BOUNTY

    # Start the quest after saving.
    if @quest.save
      redirect_to! run_path(@quest), notice: 'Quest was successfully created.'
    end
  end
  
  # PUT /quests/1
  def update
    @quest = Quest.find(params[:id])
    @quest.attributes = params[:quest]

    if @quest.valid?
      @quest.save!
      redirect_to! quests_path, notice: 'Quest was successfully updated.'
    end

    render action: "new"
  end

  # DELETE /quests/1
  def destroy
    @quest = Quest.find(params[:id])
    @quest.destroy

    redirect_to quests_url
  end
end
