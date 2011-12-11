require File.join(File.dirname(__FILE__),'..', 'test_helper.rb')

class DeepNameSpacedControllerTest < ActionController::TestCase
  tests Deep::NameSpaced::ThingsController
  def test_context
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :permitted_role do
          has_permission_on :deep_name_spaced_things, :to => :show
          has_permission_on :things, :to => :update
        end
        role :prohibited_role do
          has_permission_on :deep_name_spaced_things, :to => :update
          has_permission_on :things, :to => :show
        end
      end
    }
    request!(MockUser.new(:permitted_role), "show", reader)
    assert @controller.authorized?
    request!(MockUser.new(:prohibited_role), "show", reader)
    assert !@controller.authorized?
    request!(MockUser.new(:permitted_role), "update", reader)
    assert @controller.authorized?
    request!(MockUser.new(:prohibited_role), "update", reader)
    assert !@controller.authorized?
  end
end