# The RunsController is used to changea quest's status, 
# e.g.to start or to stop a quest 
class RunsController < ApplicationController
  before_filter :quest
  layout false, :only => [:show, :cancel]
  
  #
  # Show the form to start a new run of a quest.
  # This is valid only if the quest is not running.
  def show
    # Transfer quest ownership from the draft user to current_user, if needed.
    User.transfer! @quest => current_user
    
    # Redirect to shares/new since this will handle posting in social networks.
    # FIXME: redirecting an xhr request does notresult in an xhr request 
    # in the target controller/action
    # redirect_to new_share_path(:quest_id => @quest)
    
    @share = Share.new(:quest => @quest, :owner => current_user)
    render :template => "shares/new", :layout => "dialog"
  end

  #
  # Renders the cancel form, which will end in the destroy action.
  def cancel
  end

  #
  # Stops the run of a quest
  def destroy
    @quest.cancel!(params[:quest])
    
    flash[:success] = I18n.t("quest.action.cancelled", :quest => @quest.title)
    redirect_to quest_path(@quest)
  end

private
  
  def quest
    @quest ||= Quest.draft(params[:id])
  end

end
