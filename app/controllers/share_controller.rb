# The ShareController is used to retweet (and later potentially refacebook and whatever) 
# a quest.
class ShareController < ApplicationController
  # Show the form to share a quest
  def new
    request_identity! :twitter
    @quest = Quest.find(params[:quest_id])
  end
  
  # start the run. This action receives the form from "runs/show".
  def create
    @quest = Quest.find(params[:quest_id])
    current_user.retweet @quest
    
    redirect_to @quest, notice: "Thank your for sharing!"
  end
end
