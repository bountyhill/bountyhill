# The SharesController is used to share a quest via selected social networks, 
# e.g. twitter, facebook or ...
class SharesController < ApplicationController
  before_filter :quest, :only => [:new]
  layout false, :only => [:new]
  
  #
  # Show the form to share a quest
  def new
    @share = Share.new(:quest => @quest, :owner => current_user)
    render :layout => "dialog"
  end
  
  #
  # Create a share object
  def create
    @share = Share.new(params[:share].merge(:owner => current_user))
    
    # if we have a valid share object, we redirect to
    # the show action to trigger the actual sharing
    if @share.save
      redirect_to share_path(@share)
    end
  end
  
  #
  # Post the quest in social networks
  def show
    @share = Share.find(params[:id])
    
    # Share quest with identities user did choose
    @share.identities.each do |identity, shared_at|
      next if shared_at.kind_of?(Time)
      
      # request identity user wants to share with
      request_identity! identity.to_sym, :on_cancel => @share.quest
      @share.post(identity.to_sym)
    end

    # 
    # if the quest is alreday active we are done if not,
    # we have to start the quest
    message = if @share.quest.active? then
        I18n.t("quest.action.shared", :quest => @share.title)
      else
        @share.quest.start!
        I18n.t("quest.action.started", :quest => @share.title)
      end
    redirect_to! quest_path(@share.quest), :success => message
  end


private
  
  def quest
    @quest ||= Quest.find(params[:quest_id])
  end
    
end
