# encoding: UTF-8

class Activity < ActiveRecord::Base
  include ActiveRecord::RandomID
  
  belongs_to :user
  belongs_to :entity, :polymorphic => true
  
  GRADING = {
    :quest => {
      :create  =>  1,
      :start   =>  5,
      :share   =>  3,
      :comment =>  1,
      :stop    => -5
    },
    :offer => {
      :create   =>  1,
      :activate =>  3,
      :accept   =>  5,
      :reject   =>  1,
      :comment  =>  1,
      :withdraw => -5
    },
    :"identity/twitter" => {
      :create => 1
    },
    :"identity/facebook" => {
      :create => 1
    },
    :"identity/email" => {
      :create => 2
    },
    :"identity/address" => {
      :create => 2
    }
  }.with_indifferent_access

  def self.actions
     @actions ||= Activity::GRADING.keys.inject([]) do |arr, obj|
        arr << Activity::GRADING[obj].keys
        arr.flatten
      end.uniq
  end
  
  validates :user, :entity, :presence => true
  validates :action, :presence => true, :inclusion => Activity.actions
  validates :points, :presence => true, :numericality => true
  
  def self.log(user, action, entity)
    klass = entity.class.name.underscore
    
    unless Activity::GRADING[klass].present?
      raise ArgumentError, "Cannot handle entity class: #{klass}! Allowed are only: #{Activity::GRADING.keys.to_sentence}."
    end
    
    unless (points = Activity::GRADING[klass][action])
      raise ArgumentError, "Cannot handle action: #{action}! Allowed are only: #{Activity.actions.to_sentence}."
    end
    
    activity = user.activities.create!(
      :action => action.to_s,
      :entity => entity,
      :points => points)
    
    Bountybase.reward user
    activity
  end
  
end