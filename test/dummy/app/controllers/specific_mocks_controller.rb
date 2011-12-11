class SpecificMocksController < MocksController
  filter_access_to :test_action, :require => :test, :context => :permissions
  filter_access_to :test_action_2, :require => :test, :context => :permissions_2
  filter_access_to :show
  filter_access_to :edit, :create, :require => :test, :context => :permissions
  filter_access_to :edit_2, :require => :test, :context => :permissions,
    :attribute_check => true, :model => LoadMockObject
  filter_access_to :new, :require => :test, :context => :permissions
  
  filter_access_to [:action_group_action_1, :action_group_action_2]
  define_action_methods :test_action, :test_action_2, :show, :edit, :create,
    :edit_2, :new, :unprotected_action, :action_group_action_1, :action_group_action_2
end
