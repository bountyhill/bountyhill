# The SharesController is used to retweet (and later potentially refacebook and whatever) 
# a quest.
class SharesController < ApplicationController
  before_filter :quest
  attr :quest

  layout false, :only => [:show]
  
  # Show the form to share a quest
  def show
    request_identity! :twitter
    render :layout => "dialog"
  end
  
  def update
    # Re-render the form, if the quest is not valid.
    quest.attributes = params[:quest]
    unless quest.valid?
      flash.now[:error] = if base_errors = @quest.errors[:base]
        I18n.t("message.base_error", :base_error => base_errors.join(", "))
      else
        I18n.t("message.error")
      end

      render! action: "show"
    end
    
    # quest.tweet is a pseudo-attribute; it will be set from the form data.
    current_user.retweet(quest, :message => quest.tweet)

    flash[:success] = I18n.t("quest.shared", :title => quest.title)
    redirect_to quests_path(:owner_id => current_user.id)
  end

  private
  
  def quest
    @quest ||= Quest.find(params[:id])
  end
end
