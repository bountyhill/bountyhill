# encoding: UTF-8

class StaticController < ApplicationController
  layout :layout

  # def faq
  # def contact
  # def imprint
  # def terms
  # def privacy
  %w(faq contact imprint terms privacy).each do |static_page|
    define_method static_page do
    end
  end

private
  def layout #:nodoc:
    "static"
  end
end
