class RunsController < ApplicationController
  before_filter :quest
  
  # Show the form to start a new run of a quest.
  #
  # This is valid only if the quest is not running.
  def show
    #
    # The user must have a twitter account. (see #49) If not, she cannot
    # continue here, but gets transferred to an identity provider.
    request_identity! :twitter

    # Transfer quest ownership from the draft user to current_user, if needed.
    User.transfer! quest => current_user
    
    # set run defaults
    quest.duration_in_days = 7
    
    # Show the form.  When the user submits the form it will end up in "runs/start".
  end
  
  # start the run. This action receives the form from "runs/show".
  def update
    W "runs/update: current_user", current_user
    
    if quest.update_attributes params[:quest]
      quest.start!
    
      # quest.tweet is a pseudo-attribute; it will be set from the form data.
      current_user.retweet(quest, :message => quest.tweet)
    
      flash[:success] = I18n.t("quest.started", :title => quest.title)
      redirect_to quests_path(:owner_id => current_user.id)
    end
    
    # Re-render the form, if the quest is not valid...
  end

  # DELETE /quests/1
  # DELETE /quests/1.json
  def destroy
    quest.cancel!(params[:quest])
    current_user.retweet(quest, :message => "This quest was cancelled")

    flash[:success] = I18n.t("quest.cancelled", :title => quest.title)
    redirect_to quest_path(quest)
  end
  
  def cancel
    # render the cancel form, which will end in the destroy action.
  end

  private
  
  def quest
    W "runs: current_user", current_user
    @quest ||= Quest.draft(params[:id])
  end
end
