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
    name "twatter"

    after(:build) do |identity, evaluator| 
      identity.user = User.create! { |user| 
        user.identities << identity 
      }
    end
  end

  factory :user do
    initialize_with { Factory(:identity).user }
  end
end
