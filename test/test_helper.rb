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

class MockDataObject
  def initialize (attrs = {})
    attrs.each do |key, value|
      instance_variable_set(:"@#{key}", value)
      self.class.class_eval do
        attr_reader key
      end
    end
  end
  
  def self.descends_from_active_record?
    true
  end

  def self.table_name
    name.tableize
  end

  def self.name
    "Mock"
  end
  
  def self.find(*args)
    raise StandardError, "Couldn't find #{self.name} with id #{args[0].inspect}" unless args[0]
    new :id => args[0]
  end
end

class MockUser < MockDataObject
  def initialize (*roles)
    options = roles.last.is_a?(::Hash) ? roles.pop : {}
    super({:role_symbols => roles, :login => hash}.merge(options))
  end

  def initialize_copy (other)
    @role_symbols = @role_symbols.clone
  end
end

class MocksController < ActionController::Base
  attr_accessor :current_user
  attr_writer :authorization_engine
  
  def authorized?
    !!@authorized
  end
  
  def self.define_action_methods (*methods)
    methods.each do |method|
      define_method method do
        @authorized = true
        render :text => 'nothing'
      end
    end
  end

  def self.define_resource_actions
    define_action_methods :index, :show, :edit, :update, :new, :create, :destroy
  end
  
  def logger (*args)
    Class.new do 
      def warn(*args)
        #p args
      end
      alias_method :info, :warn
      alias_method :debug, :warn
      def warn?; end
      alias_method :info?, :warn?
      alias_method :debug?, :warn?
    end.new
  end
end

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
