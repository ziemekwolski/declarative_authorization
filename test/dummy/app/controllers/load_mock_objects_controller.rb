class LoadMockObjectsController < MocksController
  before_filter { @@load_method_call_count = 0 }
  filter_access_to :show, :attribute_check => true, :model => LoadMockObject
  filter_access_to :edit, :attribute_check => true
  filter_access_to :update, :delete, :attribute_check => true,
                   :load_method => proc {MockDataObject.new(:test => 1)}
  filter_access_to :create do
    permitted_to! :edit, :load_mock_objects
  end
  filter_access_to :view, :attribute_check => true, :load_method => :load_method
  def load_method
    self.class.load_method_called
    MockDataObject.new(:test => 2)
  end
  define_action_methods :show, :edit, :update, :delete, :create, :view

  def self.load_method_called
    @@load_method_call_count ||= 0
    @@load_method_call_count += 1
  end
  def self.load_method_call_count
    @@load_method_call_count || 0
  end
end
