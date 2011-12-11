class CommonChild2Controller < CommonController
  filter_access_to :delete
  define_action_methods :show, :delete
end
