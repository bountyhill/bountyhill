# encoding: UTF-8

FactoryGirl.factories.clear

FactoryGirl.define do
  factory :email_identity, :class => "Identity::Email" do
    name                  "esnail"
    email                 "esnail@example.com"
    password              "foobar"
    password_confirmation "foobar"

    after(:build) do |identity, evaluator|
      next if identity.user.present?
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :twitter_identity, :class => "Identity::Twitter" do |ti|
    ti.sequence(:identifier) { |i| "twatter_#{i}"}
    
    after(:build) do |identity, evaluator|
      identity.info ||= { :nickname => "twatter" }
      
      next if identity.user.present?
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :facebook_identity, :class => "Identity::Facebook" do |fi|
    fi.sequence(:identifier) { |i| "inyourfacebook_#{i}"}
    
    after(:build) do |identity, evaluator|
      identity.info ||= { :nickname => "inyourfacebook" }
      
      next if identity.user.present?
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :google_identity, :class => "Identity::Google" do |gi|
    gi.sequence(:identifier) { |i| "froogle_#{i}"}
    
    after(:build) do |identity, evaluator|
      identity.info ||= { :name => "Foo Bar" }
      
      next if identity.user.present?
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :linkedin_identity, :class => "Identity::Linkedin" do |li|
    li.sequence(:identifier) { |i| "klinkedin_#{i}"}
    
    after(:build) do |identity, evaluator|
      identity.info ||= { :name => "Foo Bar" }
      
      next if identity.user.present?
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :xing_identity, :class => "Identity::Xing" do |xing_identity|
    xing_identity.sequence(:identifier) { |i| "openbc_#{i}"}
    
    after(:build) do |identity, evaluator|
      identity.info ||= { :name => "Foo Bar" }
      
      next if identity.user.present?
      identity.user = User.create! { |user| user.identities << identity }
    end
  end
  
  factory :address_identity, :class => "Identity::Address" do
    address1  "street"
    city      "city"
    zipcode   "zipcode"
    country   "country"

    after(:build) do |identity, evaluator|
      next if identity.user.present?
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :user do
    initialize_with { Factory(:email_identity).user }
  end

  factory :quest do
    bounty      "12"
    title       "quest title"
    description "quest description"
    category    "misc"
#    association :owner, :factory => :user
  end

  factory :offer do
    title       "offer title"
    description "offer description"
    association :quest, :factory => :quest
    association :owner, :factory => :user
  end
  
  factory :comment do
    body        "comment text"
    association :commentable, :factory => :quest
    after(:build) do |comment, evaluator| 
      comment.owner = comment.commentable.owner
    end
  end
  
  factory :activity do
    action      "create"
    points      1
    association :entity, :factory => :quest
    association :user, :factory => :user
  end
  
  factory :share do
    message     "share's message"
    association :quest, :factory => :quest

    after(:build) do |share, evaluator|
      share.owner       = share.quest.owner
      share.identities  = { "twitter" => true }
    end
  end
  
  factory :location do
    address     "Berlin, Germany"
    latitude    52.519171
    longitude   13.4060912
    association :stationary, :factory => :quest
  end

  factory :message do
    subject     "message's subject"
    body        "message's body"
    association :reference, :factory => :quest
    association :sender,    :factory => :user
  end
end
