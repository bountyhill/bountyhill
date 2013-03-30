class Forward < ActiveRecord::Base
  # t.integer :quest_id           # the id of the quest
  # t.integer :sender_id          # the id of the sender
  # t.text    :text               # the text of the forward
  # t.text    :original_data      # the original data, serialized as JSON

  belongs_to :sender, :class_name => "User"
  belongs_to :quest
  
  after_create :reward_sender
  
  def reward_sender
    sender.reward_for(self.quest, :forward)
  end
  
end
