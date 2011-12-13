require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class AuthorizationRuleTest < Test::Unit::TestCase
    
  def test_should_be_able_to_store_column_information
    rule = Authorization::AuthorizationRule.new("current_role")
    assert rule.respond_to?("accessible_columns"), "Should have an attribute reader for columns"
    assert_equal rule.accessible_columns, []
  end
  
  def test_should_append_column_into_accessible_columns
    rule = Authorization::AuthorizationRule.new("current_role")
    rule.append_columns(:column_one)
    assert_equal rule.accessible_columns, [:column_one]
  end
  
  def test_should_append_series_of_columns_into_accessible_columns
    rule = Authorization::AuthorizationRule.new("current_role")
    rule.append_columns([:column_one, :column_two])
    assert_equal rule.accessible_columns, [:column_one, :column_two]
  end
  
  def test_should_append_to_existing_accessiable_columns
    rule = Authorization::AuthorizationRule.new("current_role")
    rule.append_columns([:column_one, :column_two])
    rule.append_columns([:column_three, :column_four])
    assert_equal rule.accessible_columns, [:column_one, :column_two, :column_three, :column_four]
  end
  
  def test_should_set_column_accessiable_via_options
    rule = Authorization::AuthorizationRule.new("current_role", [:read], :perms, :or, {:on_columns => :name})
    assert_equal [:name], rule.accessible_columns
  end
end
