class QuestsController < ApplicationController
  include ApplicationController::ImageParameters
  
  # GET /quests
  def index
    scope = if params[:owner_id]
      User.find(params[:owner_id]).quests
    else
      Quest.active
    end

    @quests = scope.paginate(:page => params[:page], :per_page => per_page, :include => {:owner => :identities})
  end

  # GET /quests/1
  def show
    @quest = Quest.find(params[:id])
  end

  def new
    @quest = Quest.new

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
    params[:quest][:image] = image_param
    @quest = Quest.new(params[:quest])
    @quest.owner ||= User.draft

    # Start the quest after saving.
    if @quest.save
      redirect_to! run_path(@quest), notice: 'Quest was successfully created.'
    end

    # rerender form if quest could not be saved
    flash.now[:error] = if base_errors = @quest.errors[:base]
      I18n.t("quest.message.base_error", :base_error => base_errors.join(", "))
    else
      I18n.t("quest.message.error")
    end

    render action: "new"
  end
  
  # PUT /quests/1
  def update
    @quest = Quest.find(params[:id])
    @quest.attributes = params[:quest]

    if @quest.valid?
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
  
  # GET /quests/1/share
  def retweet
    request_identity! :twitter
    
    @quest = Quest.find(params[:id])
    current_user.retweet @quest
    
    redirect_to @quest, notice: "Thank your for sharing!"
  end
end
