class MocksController < ApplicationController
  
  %w(quests offers).each do |mock|
    define_method mock do
      render "mocks/#{mock}/#{(params[:page] || "index")}"
    end
  end
  
end
