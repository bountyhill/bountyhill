FactoryGirl.factories.clear

FactoryGirl.define do
  factory :identity, :class => "Identity::Email" do
    name     "Foo Bar"
    email    "foo.bar@example.com"
    password "foobar"

    after(:build) do |identity, evaluator| 
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :twitter_identity, :class => "Identity::Twitter" do
    identifier "twatter"

    after(:build) do |identity, evaluator| 
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :facebook_identity, :class => "Identity::Facebook" do
    identifier "inyourfacebook"

    after(:build) do |identity, evaluator| 
      identity.user = User.create! { |user| user.identities << identity }
    end
  end

  factory :user do
    initialize_with { Factory(:identity).user }
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
#    association :owner, :factory => :user
  end
  
  factory :comment do
    body        "comment text"
    association :commentable, :factory => :quest
    association :owner, :factory => :user
  end
  
  factory :activity do
    action      "create"
    points      1
    association :object, :factory => :quest
    association :user, :factory => :user
  end
  
  factory :share do |share|
    message    "share's message"
    association :quest, :factory => :quest

    after(:build) do |share, evaluator| 
      share.owner = share.quest.owner
    end
  end
end
