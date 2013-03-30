module ActivityAssertions
  
  def assert_activity_logged(object, action=:create, user=nil, &block)
    Bountybase.stubs :reward
    Activity.expects(:log).with(user || object.owner, action, object)
    yield
  end
  
end