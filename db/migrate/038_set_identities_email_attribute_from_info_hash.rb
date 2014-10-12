# encoding: UTF-8

class SetIdentitiesEmailAttributeFromInfoHash < ActiveRecord::Migration
  def up
    Identity.oauth_identities.each do |id|
      "Identity::#{id.to_s.camelize}".constantize.all.each do |identity|
        Identity.update_all({ :email => identity.email }, { :id => identity.id })
      end
    end
  end

  def down
    Identity.oauth_identities.each do |identity_class|
      "Identity::#{id.to_s.camelize}".constantize.all.each do |identity|
        Identity.update_all({ :email => nil }, { :id => identity.id })
      end
    end
  end
end
