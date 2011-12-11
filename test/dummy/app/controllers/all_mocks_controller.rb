class AllMocksController < MocksController
  filter_access_to :all
  filter_access_to :view, :require => :test, :context => :permissions
  define_action_methods :show, :view
end
