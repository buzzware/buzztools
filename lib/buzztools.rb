#require "buzztools/version"
Dir.chdir(File.dirname(__FILE__)) { Dir['buzztools/*.rb'] }.each {|f| require f }

#module Buzztools
#  module Rails
#    class Engine < ::Rails::Engine
#    end
#  end
#end
