require File.join(File.dirname(__FILE__), 'test_helper.rb')
require File.join(File.dirname(__FILE__), %w{.. lib declarative_authorization maintenance})

class MaintenanceTest < Test::Unit::TestCase
  include Authorization::TestHelper
  class UsageTestController < ActionController::Base
    filter_access_to :an_action
    def an_action
      
    end
  end

  def test_usages_by_controllers
    assert Authorization::Maintenance::Usage::usages_by_controller.
              include?(UsageTestController)
  end

  def test_without_access_control
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test
        end
      end
    }
    engine = Authorization::Engine.new(reader)
    assert !engine.permit?(:test_2, :context => :permissions,
        :user => MockUser.new(:test_role))
    Authorization::Maintenance::without_access_control do
      assert engine.permit!(:test_2, :context => :permissions,
          :user => MockUser.new(:test_role))
    end
    without_access_control do
      assert engine.permit?(:test_2, :context => :permissions,
          :user => MockUser.new(:test_role))
    end
    Authorization::Maintenance::without_access_control do
      Authorization::Maintenance::without_access_control do
        assert engine.permit?(:test_2, :context => :permissions,
            :user => MockUser.new(:test_role))
      end
      assert engine.permit?(:test_2, :context => :permissions,
          :user => MockUser.new(:test_role))
    end
  end

end