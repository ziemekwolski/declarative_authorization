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
