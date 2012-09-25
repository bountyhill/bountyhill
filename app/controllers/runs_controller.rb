class RunsController < ApplicationController
  before_filter :quest
  
  # Start a new run, based on a given quest
  def show
    requires_identity! :confirmed, :transfer => quest
  end
  
  # Start the quest
  def update
    quest.attributes = params[:quest]

    unless false && quest.valid?
      flash.now[:error] = if base_errors = @quest.errors[:base]
        I18n.t("quest.message.base_error", :base_error => base_errors.join(", "))
      else
        I18n.t("quest.message.error")
      end

      render action: "show"
      return
    end
    
    # (Try to) save
    quest.save!
    quest.start!

    # After creation start the quest
    redirect_to quest_path(quest), notice: 'Quest was successfully started.'
  end

  # DELETE /quests/1
  # DELETE /quests/1.json
  def destroy
    quest.cancel!
    redirect_to quest_path(quest)
  end

  private
  
  def quest
    @quest ||= Quest.draft(params[:id])
  end
end
