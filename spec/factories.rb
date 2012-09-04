FactoryGirl.define do
  factory :identity, :class => "Identity::Email" do |i|
    name     "Foo Bar"
    email    "foo.bar@example.com"
    password "foobar"

    i.after_build do |identity| 
      identity.user = User.create! { |user| user.identities << identity }
    end
  end
end