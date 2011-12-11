# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
DA_ROOT = File.join(File.dirname(__FILE__), %w{.. lib})
require File.join(File.dirname(__FILE__), %w{.. lib declarative_authorization rails_legacy})
require File.join(File.dirname(__FILE__), %w{.. lib declarative_authorization authorization})
require File.join(File.dirname(__FILE__), %w{.. lib declarative_authorization in_controller})
require File.join(File.dirname(__FILE__), %w{.. lib declarative_authorization maintenance})


if Rails.version < "3"
  ActionController::Routing::Routes.draw do |map|
    map.connect ':controller/:action/:id'
  end
else
  #Routes defined in dummy framework
end

ActionController::Base.send :include, Authorization::AuthorizationInController
if Rails.version < "3"
  require "action_controller/test_process"
end

class Test::Unit::TestCase
  include Authorization::TestHelper
  
  def request! (user, action, reader, params = {})
    action = action.to_sym if action.is_a?(String)
    @controller.current_user = user
    @controller.authorization_engine = Authorization::Engine.new(reader)
    
    ((params.delete(:clear) || []) + [:@authorized]).each do |var|
      @controller.instance_variable_set(var, nil)
    end
    get action, params
  end

  unless Rails.version < "3"
    def setup
      #@routes = Rails::Application.routes
      @routes = Rails.application.routes
    end
  end
end