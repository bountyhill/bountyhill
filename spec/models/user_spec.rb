require 'spec_helper'

describe User do

  before do
    @user = User.new(
      name: "Foo Bar",
      email: "foo@bar.net",
      password: "foobar",
      password_confirmation: "foobar"
    )
  end 

  subject { @user }

  %w(name email password password_confirmation password_digest authenticate remember_token).each do |attribute|
    it { should respond_to(attribute) }
  end

  %w(name email password password_confirmation).each do |attribute|
    it { should be_valid }

    describe "when #{attribute} is not present" do
      before { @user.send("#{attribute}=", " ") }
      it { should_not be_valid }
    end
  end

  describe "remember token is present" do
    before { @user.save }
    its(:remember_token) { should_not be_blank }
  end

  describe "when name is too long" do
    before { @user.name = "a" * (User::MAX_NAME_LENGTH+1) }
    it { should_not be_valid }
  end

  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = "a" * (User::MIN_PASSWORD_LENGTH-1) }
    it { should be_invalid }
  end

  describe "when email format is invalid" do
    invalid_addresses =  %w[user@foo,com user_at_foo.org example.user@foo.]
    invalid_addresses.each do |invalid_address|
      before { @user.email = invalid_address }
      it { should_not be_valid }
    end
  end

  describe "when email format is valid" do
    valid_addresses = %w[user@foo.com A_USER@f.b.org frst.lst@foo.jp a+b@baz.cn]
    valid_addresses.each do |valid_address|
      before { @user.email = valid_address }
      it { should be_valid }
    end
  end

  describe "when email address is already taken" do
    before do
      another_user_with_same_email = @user.dup
      another_user_with_same_email.email = @user.email.upcase
      another_user_with_same_email.save
    end
    it { should_not be_valid }
  end

  describe "when password doesn't match confirmation" do
    before { @user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end

  describe "with valid information" do
    before { @user.save }
    let(:found_user) { User.find_by_email(@user.email) }

    describe "with valid password" do
      it { should == found_user.authenticate(@user.password) }
    end

    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }

      it { should_not == user_for_invalid_password }
      specify { user_for_invalid_password.should be_false }
    end
  end

end
