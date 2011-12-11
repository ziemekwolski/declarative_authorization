class CommonChild1Controller < CommonController
  filter_access_to :all, :context => :context_1
end
