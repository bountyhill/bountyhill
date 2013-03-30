# encoding: utf-8

class Activity < ActiveRecord::Base
  include ActiveRecord::RandomID
  
  belongs_to :user
  belongs_to :object, :polymorphic => true
  
  GRADING = {
    :quest => {
      :forward => 3,
      :comment => 1,
      :create  => 5,
      :start   => 10,
      :stop    => -5
    },
    :offer => {
      :comment  => 2,
      :create   => 10,
      :withdraw => -5,
      :accept   => 20,
      :reject   => 5
    },
    :"identity/twitter" => {
      :create => 5
    },
    :"identity/email" => {
      :create => 10
    }
  }.with_indifferent_access

  def self.actions
     @actions ||= Activity::GRADING.keys.inject([]) do |arr, obj|
        arr << Activity::GRADING[obj].keys
        arr.flatten
      end
  end
  
  validates :user, :object, :presence => true
  validates :action, :presence => true, :inclusion => Activity.actions
  validates :points, :presence => true, :numericality => true
  
  def self.log(user, action, object)
    klass = object.class.name.underscore
    
    unless Activity::GRADING[klass].present?
      raise ArgumentError, "Cannot handle object class: #{klass}! Allowed are only: #{Activity::GRADING.keys.to_sentence}."
    end
    
    unless (points = Activity::GRADING[klass][action])
      raise ArgumentError, "Cannot handle action: #{action}! Allowed are only: #{Activity.actions.to_sentence}."
    end
    
    activity = user.activities.create!(
      :action => action.to_s,
      :object => object,
      :points => points)
    
    Bountybase.reward user, :points => points
    activity
  end
  
end