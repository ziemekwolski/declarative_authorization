require File.join(File.dirname(__FILE__),'..', 'test_helper.rb')

class HierachicalControllerTest < ActionController::TestCase
  tests CommonChild2Controller
  def test_controller_hierarchy
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :mocks, :to => [:delete, :show]
        end
      end
    }
    request!(MockUser.new(:test_role), "show", reader)
    assert !@controller.authorized?
    request!(MockUser.new(:test_role), "delete", reader)
    assert !@controller.authorized?
  end
end
