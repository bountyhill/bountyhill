module ActivityAssertions
  
  def assert_activity_logged(action=:create, object=nil, &block)
    if object
      user =   object.owner if object.respond_to?(:owner)
      user ||= object.user  if object.respond_to?(:user)

      Activity.expects(:log).with(user, action, object)
    else
      Activity.expects(:log)
    end

    Bountybase.stubs :reward
    yield
  end
  
end