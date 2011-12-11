class Deep::NameSpaced::ThingsController < MocksController
  filter_access_to :show
  filter_access_to :update, :context => :things
  define_action_methods :show, :update
end
