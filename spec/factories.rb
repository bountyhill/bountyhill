FactoryGirl.factories.clear

FactoryGirl.define do
  factory :identity, :class => "Identity::Email" do
    name     "Foo Bar"
    email    "foo.bar@example.com"
    password "foobar"

    after(:build) do |identity, evaluator| 
      identity.user = User.create! { |user| 
        user.identities << identity 
      }
    end
  end

  factory :twitter_identity, :class => "Identity::Twitter" do
    email "twatter"

    after(:build) do |identity, evaluator| 
      identity.user = User.create! { |user| 
        user.identities << identity 
      }
    end
  end

  factory :user do
    initialize_with { Factory(:identity).user }
  end

  factory :quest do
    bounty "12"
    title "bountytitle"
    description "bounty description"
  end

  factory :offer do
    description "offer description"
  end
end
