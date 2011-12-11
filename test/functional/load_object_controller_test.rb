require File.join(File.dirname(__FILE__),'..', 'test_helper.rb')

class LoadObjectControllerTest < ActionController::TestCase
  tests LoadMockObjectsController
  
  def test_filter_access_with_object_load
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :load_mock_objects, :to => [:show, :edit] do
            if_attribute :id => 1
            if_attribute :id => "1"
          end
        end
      end
    }
    
    request!(MockUser.new(:test_role), "show", reader, :id => 2)
    assert !@controller.authorized?
    
    request!(MockUser.new(:test_role), "show", reader, :id => 1,
      :clear => [:@load_mock_object])
    assert @controller.authorized?
    
    request!(MockUser.new(:test_role), "edit", reader, :id => 1,
      :clear => [:@load_mock_object])
    assert @controller.authorized?
    assert @controller.instance_variable_defined?(:@load_mock_object)
  end

  def test_filter_access_object_load_without_param
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :load_mock_objects, :to => [:show, :edit] do
            if_attribute :id => is {"1"}
          end
        end
      end
    }

    assert_raise StandardError, "No id param supplied" do
      request!(MockUser.new(:test_role), "show", reader)
    end
    
    Authorization::AuthorizationInController.failed_auto_loading_is_not_found = false
    assert_nothing_raised "Load error is only logged" do
      request!(MockUser.new(:test_role), "show", reader)
    end
    assert !@controller.authorized?
    Authorization::AuthorizationInController.failed_auto_loading_is_not_found = true
  end
  
  def test_filter_access_with_object_load_custom
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :load_mock_objects, :to => :view do
            if_attribute :test => is {2}
          end
          has_permission_on :load_mock_objects, :to => :update do
            if_attribute :test => is {1}
          end
          has_permission_on :load_mock_objects, :to => :delete do
            if_attribute :test => is {2}
          end
        end
      end
    }
    
    request!(MockUser.new(:test_role), "delete", reader)
    assert !@controller.authorized?
    
    request!(MockUser.new(:test_role), "view", reader)
    assert @controller.authorized?
    assert_equal 1, @controller.class.load_method_call_count
    
    request!(MockUser.new(:test_role_2), "view", reader)
    assert !@controller.authorized?
    assert_equal 1, @controller.class.load_method_call_count

    request!(MockUser.new(:test_role), "update", reader)
    assert @controller.authorized?
  end
  
  def test_filter_access_custom
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :load_mock_objects, :to => :edit
        end
        role :test_role_2 do
          has_permission_on :load_mock_objects, :to => :create
        end
      end
    }
    
    request!(MockUser.new(:test_role), "create", reader)
    assert @controller.authorized?
    
    request!(MockUser.new(:test_role_2), "create", reader)
    assert !@controller.authorized?
  end
end
