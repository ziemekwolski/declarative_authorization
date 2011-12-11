require File.join(File.dirname(__FILE__),'..', 'test_helper.rb')

class BasicControllerTest < ActionController::TestCase
  tests SpecificMocksController
  
  def test_filter_access_to_receiving_an_explicit_array
    reader = Authorization::Reader::DSLReader.new

    reader.parse %{
      authorization do
        role :test_action_group_2 do
          has_permission_on :specific_mocks, :to => :action_group_action_2
        end
      end
    }

    request!(MockUser.new(:test_action_group_2), "action_group_action_2", reader)
    assert @controller.authorized?
    request!(MockUser.new(:test_action_group_2), "action_group_action_1", reader)
    assert !@controller.authorized?
    request!(nil, "action_group_action_2", reader)
    assert !@controller.authorized?
  end
  
  def test_filter_access
    assert !@controller.class.before_filters.empty?
    
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test
          has_permission_on :specific_mocks, :to => :show
        end
      end
    }
    
    request!(MockUser.new(:test_role), "test_action", reader)
    assert @controller.authorized?
    
    request!(MockUser.new(:test_role), "test_action_2", reader)
    assert !@controller.authorized?
    
    request!(MockUser.new(:test_role_2), "test_action", reader)
    assert_response :forbidden
    assert !@controller.authorized?
    
    request!(MockUser.new(:test_role), "show", reader)
    assert @controller.authorized?
  end
  
  def test_filter_access_multi_actions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test
        end
      end
    } 
    request!(MockUser.new(:test_role), "create", reader)
    assert @controller.authorized?
  end
  
  def test_filter_access_unprotected_actions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
        end
      end
    }
    request!(MockUser.new(:test_role), "unprotected_action", reader)
    assert @controller.authorized?
  end

  def test_filter_access_priv_hierarchy
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      privileges do
        privilege :read do
          includes :list, :show
        end
      end
      authorization do
        role :test_role do
          has_permission_on :specific_mocks, :to => :read
        end
      end
    }
    request!(MockUser.new(:test_role), "show", reader)
    assert @controller.authorized?
  end
  
  def test_filter_access_skip_attribute_test
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test do
            if_attribute :id => is { user }
          end
        end
      end
    }
    request!(MockUser.new(:test_role), "new", reader)
    assert @controller.authorized?
  end
  
  def test_existing_instance_var_remains_unchanged
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test do
            if_attribute :id => is { 5 }
          end
        end
      end
    }
    mock_object = MockDataObject.new(:id => 5)
    @controller.send(:instance_variable_set, :"@load_mock_object",
        mock_object)
    request!(MockUser.new(:test_role), "edit_2", reader)
    assert_equal mock_object, 
      @controller.send(:instance_variable_get, :"@load_mock_object")
    assert @controller.authorized?
  end

  def test_permitted_to_without_context
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :specific_mocks, :to => :test
        end
      end
    }
    @controller.current_user = MockUser.new(:test_role)
    @controller.authorization_engine = Authorization::Engine.new(reader)
    assert @controller.permitted_to?(:test)
  end
end
