class Name::SpacedThingsController < MocksController
  filter_access_to :show
  filter_access_to :update, :context => :spaced_things
  define_action_methods :show, :update
end
