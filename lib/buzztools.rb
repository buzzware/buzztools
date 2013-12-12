#require "buzztools/version"
Dir.chdir(File.dirname(__FILE__)) { Dir['buzzcore/*.rb'] }.each {|f| require f }

#module Buzztools
#  module Rails
#    class Engine < ::Rails::Engine
#    end
#  end
#end
