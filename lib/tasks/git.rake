# encoding: UTF-8

namespace :git do
  desc "Tag and push repository"
  task :push do
    require 'bundler/gem_helper'
    require 'bundler/ui'

    class GemHelper < Bundler::GemHelper
      def initialize
        Bundler.ui = Bundler::UI::Shell.new(Thor::Base.shell.new)
        @base = (base ||= Dir.pwd)
      end

      public :guard_clean, :guard_already_tagged, :tag_version, :git_push

      def version
        Time.now.strftime("%Y%m%d.%H%M")
      end
    end

    g = GemHelper.new

    g.guard_clean
    g.guard_already_tagged
    g.tag_version do
      Bundler.ui.confirm "Pushing git commits"
      g.git_push
    end
  end
end
