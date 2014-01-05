# encoding: UTF-8

class MessagesController < ApplicationController
  
  def new
    @message = Message.new(params[:message])
    render :layout => "dialog"
  end
  
  def create
    @message = Message.new(params[:message])
    @message.sender = current_user
    
    # if we have a valid message object, we send an email after it's creation
    if @message.save
      flash[:success] = I18n.t("notice.send.success", :record => @message.subject)
      
      # after sending the message, redirect to it's reference path
      # wich will be either a quest or an offer
      redirect_to! self.send("#{@message.reference_type.underscore}_path", @message.reference)
    end
  end
  
end
