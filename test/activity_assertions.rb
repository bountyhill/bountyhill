# encoding: UTF-8

module ActivityAssertions
  
  def assert_activity_logged(action=:create, entity=nil, &block)
    if entity
      user =   entity.owner if entity.respond_to?(:owner)
      user ||= entity.user  if entity.respond_to?(:user)

      Activity.expects(:log).with(user, action, entity)
    else
      Activity.expects(:log)
    end

    Bountybase.stubs :reward
    yield
  end
  
end