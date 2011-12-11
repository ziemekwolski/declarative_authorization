class AccessOverwritesController < MocksController
  filter_access_to :test_action, :test_action_2, 
    :require => :test, :context => :permissions_2
  filter_access_to :test_action, :require => :test, :context => :permissions
  define_action_methods :test_action, :test_action_2
end
