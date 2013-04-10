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

    if params[:preview]
      render action: "preview"
    end
  end

  def new
    @quest ||= Quest.new
    @quest.bounty_in_cents = Quest::DEFAULT_BOUNTY

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
      redirect_to! quest_path(@quest, preview: true), notice: 'Quest was successfully created.'
    end

    render action: "new"
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
