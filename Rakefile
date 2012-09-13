#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Bountyhill::Application.load_tasks

#
# This makes sure that the default rake task runs the "test:units" task also.
task :default => "test:units"



# $:.unshift File.expand_path('../vendor', __FILE__)
#require 'thor'
require 'bundler/gem_helper'
require 'bundler/ui'

class GemHelper < Bundler::GemHelper
  def initialize
    Bundler.ui = Bundler::UI::Shell.new(Thor::Base.shell.new)
    @base = (base ||= Dir.pwd)
  end
  
  public :guard_clean
end

task :prepare do
  g = GemHelper.new

  #g.extend 
  g.guard_clean
  g.guard_already_tagged
  g.tag_version {
    g.git_push
  }
end
__END__

module Bundler
  class GemHelper
    include Rake::DSL if defined? Rake::DSL

    class << self
      # set when install'd.
      attr_accessor :instance

      def install_tasks(opts = {})
        new(opts[:dir], opts[:name]).install
      end

      def gemspec(&block)
        gemspec = instance.gemspec
        block.call(gemspec) if block
        gemspec
      end
    end

    attr_reader :spec_path, :base, :gemspec

    def initialize(base = nil, name = nil)
      Bundler.ui = UI::Shell.new(Thor::Base.shell.new)
      @base = (base ||= Dir.pwd)
      gemspecs = name ? [File.join(base, "#{name}.gemspec")] : Dir[File.join(base, "{,*}.gemspec")]
      raise "Unable to determine name from existing gemspec. Use :name => 'gemname' in #install_tasks to manually set it." unless gemspecs.size == 1
      @spec_path = gemspecs.first
      @gemspec = Bundler.load_gemspec(@spec_path)
    end

    def install
      desc "Build #{name}-#{version}.gem into the pkg directory"
      task 'build' do
        build_gem
      end

      desc "Build and install #{name}-#{version}.gem into system gems"
      task 'install' do
        install_gem
      end

      desc "Create tag #{version_tag} and build and push #{name}-#{version}.gem to Rubygems"
      task 'release' do
        release_gem
      end

      GemHelper.instance = self
    end

    def build_gem
      file_name = nil
      sh("gem build -V '#{spec_path}'") { |out, code|
        file_name = File.basename(built_gem_path)
        FileUtils.mkdir_p(File.join(base, 'pkg'))
        FileUtils.mv(built_gem_path, 'pkg')
        Bundler.ui.confirm "#{name} #{version} built to pkg/#{file_name}"
      }
      File.join(base, 'pkg', file_name)
    end

    def install_gem
      built_gem_path = build_gem
      out, _ = sh_with_code("gem install '#{built_gem_path}'")
      raise "Couldn't install gem, run `gem install #{built_gem_path}' for more detailed output" unless out[/Successfully installed/]
      Bundler.ui.confirm "#{name} (#{version}) installed"
    end

    def release_gem
      guard_clean
      guard_already_tagged
      built_gem_path = build_gem
      tag_version {
        git_push
        rubygem_push(built_gem_path)
      }
    end
