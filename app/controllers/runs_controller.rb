class RunsController < ApplicationController
  before_filter :quest
  
  # Show the form to start a new run of a quest.
  #
  # This is valid only if the quest is not running.
  def show
    #
    # The user must have a confirmed email address. If not, she cannot
    # continue here, but gets transferred to an identity provider.
    request_identity! :confirmed

    # Transfer quest ownership from the draft user to current_user, if needed.
    User.transfer! quest => current_user
    
    # set run defaults
    quest.duration_in_days = 7
    
    # Show the form.  When the user submits the form it will end up in "runs/start".
  end
  
  # start the run. This action receives the form from "runs/show".
  def update
    W "runs/update: current_user", current_user
    
    # Re-render the form, if the quest is not valid?
    unless quest.update_attributes params[:quest]
      flash.now[:error] = if base_errors = @quest.errors[:base]
        I18n.t("quest.message.base_error", :base_error => base_errors.join(", "))
      else
        I18n.t("quest.message.error")
      end

      render! action: "show"
    end
    
    redirect_to! "/runs/#{quest.id}/start"
  end
  
  # This method is called as an *action* after a redirection from the
  # twitter identity provision or as a *method* from the create action.
  def start
    request_identity! :twitter

    W "runs/start: current_user", current_user

    # If there is no twitter identity yet, ask the user to provide one;
    # but go to do_start even if he chooses not to do so.
    quest.start!
    current_user.retweet(quest)

    flash[:success] = I18n.t("quest.started", :title => quest.title)
    redirect_to quest
  end

  # DELETE /quests/1
  # DELETE /quests/1.json
  def destroy
    quest.cancel!
    flash[:success] = I18n.t("quest.cancelled", :title => quest.title)
    redirect_to quest_path(quest)
  end

  private
  
  def quest
    W "runs: current_user", current_user
    @quest ||= Quest.draft(params[:id])
  end
end
