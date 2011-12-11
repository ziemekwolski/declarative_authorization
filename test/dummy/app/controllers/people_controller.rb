class PeopleController < MocksController
  filter_access_to :all
  define_action_methods :show
end
