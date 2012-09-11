class MocksController < ApplicationController
  
  %w(quests offers).each do |mock|
    define_method mock do
      page ||= "index"
      render "mocks/#{mock}/#{page}"
    end
  end
  
end
