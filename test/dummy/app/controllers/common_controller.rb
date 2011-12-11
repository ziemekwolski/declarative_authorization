class CommonController < MocksController
  filter_access_to :delete, :context => :common
  filter_access_to :all
end
