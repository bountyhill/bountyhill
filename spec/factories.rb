FactoryGirl.define do
  factory :identity, :class => "Identity::Email" do
    name     "Foo Bar"
    email    "foo.bar@example.com"
    password "foobar"
  end

  factory :user do |u|
    u.after_build { |user| user.identities << Factory(:identity, :user => user) }
  end
end