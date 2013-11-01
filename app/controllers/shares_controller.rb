# encoding: UTF-8

# The SharesController is used to share a quest via selected social networks, 
# e.g. twitter, facebook, google, linkedin or xing
class SharesController < ApplicationController
  layout false, :only => [:new, :create]
  
  #
  # Show the form to share a quest
  def new
    @quest = Quest.find(params[:quest_id])
    @share = Share.new(:title => @quest.title, :quest => @quest, :owner => current_user)
    @share.init_identities
    render :layout => "dialog"
  end
  
  #
  # Create a share object
  def create
    @quest = Quest.find(params[:share][:quest_id])
    @share = Share.new(params[:share].merge(:owner => current_user || User.draft))
    
    # if we have a valid share object, we redirect to
    # the show action to trigger the actual sharing
    if @share.save
      redirect_to! share_path(@share)
    end
  end
  
  #
  # Post the quest in social networks
  # TODO: this should rather be an update action, but
  # keep in mind that request_identity! redirects to it after
  # user's identity was provided!
  def show
    @share = Share.find(params[:id])
    @quest = Quest.find(@share.quest_id)
    
    # Share quest with identities user did choose
    @share.identities.each do |identity, post|
      next if post.kind_of?(Time) # quest was already posted with this identity
      next unless post            # quest is not to be posted with this identity

      # request identity user wants to share with
      request_identity! identity.to_sym, :on_cancel => @share.quest
      @share.post(identity.to_sym)
    end

    # 
    # if the quest is alreday active we are done if not,
    # we have to start the quest
    flash[:success] = if @quest.active?
        I18n.t("quest.action.shared", :quest => @quest.title)
      else
        @quest.start!
        I18n.t("quest.action.started", :quest => @quest.title)
      end
    redirect_to! quest_path(@quest)
  end

end
