require File.join(File.dirname(__FILE__),'..', 'test_helper.rb')

class AccessOverwritesControllerTest < ActionController::TestCase
  def test_filter_access_overwrite
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test
        end
      end
    }
    request!(MockUser.new(:test_role), "test_action_2", reader)
    assert !@controller.authorized?
    
    request!(MockUser.new(:test_role), "test_action", reader)
    assert @controller.authorized?
  end
end
