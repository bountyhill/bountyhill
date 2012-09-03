require 'spec_helper'

describe Identity do

  before do
    @identity = Identity::Email.new(
      name: "Foo Bar",
      email: "foo@bar.net",
      password: "foobar",
      password_confirmation: "foobar"
    )
  end 

  subject { @identity }

  %w(name email password password_confirmation password_digest authenticate remember_token).each do |attribute|
    it { should respond_to(attribute) }
  end

  %w(name email password password_confirmation).each do |attribute|
    it { should be_valid }

    describe "when #{attribute} is not present" do
      before { @identity.send("#{attribute}=", " ") }
      it { should_not be_valid }
    end
  end

  describe "remember token is present" do
    before { @identity.save }
    its(:remember_token) { should_not be_blank }
  end

  describe "when name is too long" do
    before { @identity.name = "a" * (Identity::Email::MAX_NAME_LENGTH+1) }
    it { should_not be_valid }
  end

  describe "with a password that's too short" do
    before { @identity.password = @identity.password_confirmation = "a" * (Identity::Email::MIN_PASSWORD_LENGTH-1) }
    it { should be_invalid }
  end

  describe "when email format is invalid" do
    invalid_addresses =  %w[user@foo,com user_at_foo.org example.user@foo.]
    invalid_addresses.each do |invalid_address|
      before { @identity.email = invalid_address }
      it { should_not be_valid }
    end
  end

  describe "when email format is valid" do
    valid_addresses = %w[user@foo.com A_USER@f.b.org frst.lst@foo.jp a+b@baz.cn]
    valid_addresses.each do |valid_address|
      before { @identity.email = valid_address }
      it { should be_valid }
    end
  end

  describe "when email address is already taken" do
    before do
      another_user_with_same_email = @identity.dup
      another_user_with_same_email.email = @identity.email.upcase
      another_user_with_same_email.save
    end
    it { should_not be_valid }
  end

  describe "when password doesn't match confirmation" do
    before { @identity.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end

  describe "with valid information" do
    before { @identity.save }
    let(:found_user) { Identity.find_by_email(@identity.email) }

    describe "with valid password" do
      it { should == found_user.authenticate(@identity.password) }
    end

    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }

      it { should_not == user_for_invalid_password }
      specify { user_for_invalid_password.should be_false }
    end
  end

end
