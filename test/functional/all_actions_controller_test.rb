require File.join(File.dirname(__FILE__),'..', 'test_helper.rb')

class AllActionsControllerTest < ActionController::TestCase
  tests AllMocksController
  def test_filter_access_all
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test
          has_permission_on :all_mocks, :to => :show
        end
      end
    }
    
    request!(MockUser.new(:test_role), "show", reader)
    assert @controller.authorized?
    
    request!(MockUser.new(:test_role), "view", reader)
    assert @controller.authorized?
    
    request!(MockUser.new(:test_role_2), "show", reader)
    assert !@controller.authorized?
  end
end
