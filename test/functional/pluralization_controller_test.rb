require File.join(File.dirname(__FILE__),'..', 'test_helper.rb')

class PluralizationControllerTest < ActionController::TestCase
  tests PeopleController
  
  def test_filter_access_people_controller
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :people, :to => :show
        end
      end
    }
    request!(MockUser.new(:test_role), "show", reader)
    assert @controller.authorized?
  end
end
