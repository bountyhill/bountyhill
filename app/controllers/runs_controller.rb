# encoding: UTF-8

# The RunsController is used to change a quest's status, 
# e.g.to start or to stop a quest 
class RunsController < ApplicationController
  before_filter :init_quest
  
  layout false, :only => [:show, :cancel]
  
  #
  # Show the form to start a new run of a quest.
  # This is valid only if the quest is not running.
  def show
    request_identity! :login, :on_cancel => @quest

    # Transfer quest ownership from the draft user to current_user, if needed.
    User.transfer! @quest => current_user
    
    request_identity! :address, :on_cancel => @quest if current_user.commercial?
    
    # Redirect to shares/new since this will handle posting in social networks.
    # FIXME: redirecting an xhr request does notresult in an xhr request 
    # in the target controller/action
    # redirect_to new_share_path(:quest_id => @quest)
    
    @share = Share.new(:title => @quest.title, :quest => @quest, :owner => current_user)
    @share.init_identities

    render :template => "shares/new", :layout => "dialog"
  end

  #
  # Renders the cancel form, which will end in the destroy action.
  def cancel
  end

  #
  # Stops the run of a quest
  def destroy
    @quest.stop!(params[:quest])
    
    flash[:success] = I18n.t("quest.action.stopped", :quest => @quest.title)
    redirect_to quest_path(@quest)
  end

private
  
  # init quest either for current user or
  # for draft user if identity was previously missing
  def init_quest
    @quest =   Quest.find_by_id(params[:id])
    @quest ||= Quest.draft(params[:id])
  end

end
