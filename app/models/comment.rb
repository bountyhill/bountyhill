class Comment < ActiveRecord::Base
  opinio

  def self.default_per_page
     10
   end
end
