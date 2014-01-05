# encoding: UTF-8

#
# The Message model encapsulates an email message's attributes
# This model is just for validation
class Message < ActiveRecord::Base
  belongs_to :sender,   :class_name => User
  belongs_to :receiver, :class_name => User
  belongs_to :reference, :polymorphic => true
  
  validates :sender, :receiver, :subject, :body, :presence => true
  validates :reference_id,   :presence => true, :numericality => true
  validates :reference_type, :presence => true, :inclusion => %w(Quest Offer)
  
  before_validation :set_receiver
  after_create      :send_message
  
  private
  
  def set_receiver
    return if     self.receiver.present?
    return unless self.reference.present?
    
    self.receiver = self.reference.owner
  end
  
  def send_message
    mail = UserMailer.contact_owner(self)
    Deferred.mail(mail)
  end
end