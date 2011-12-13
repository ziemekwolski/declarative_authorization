require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class AuthorizationRuleTest < Test::Unit::TestCase
    
  def test_should_be_able_to_store_column_information
    rule = Authorization::AuthorizationRule.new("current_role")
    assert rule.respond_to?("accessible_columns"), "Should have an attribute reader for columns"
    assert_equal rule.accessible_columns, []
  end
  
  def test_should_convert_string_columns_to_symbols
    rule = Authorization::AuthorizationRule.new("current_role")
    rule.append_columns(["column_one", "column_two"])
    assert_equal rule.accessible_columns, [:column_one, :column_two]
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
  
  def test_initializer_should_convert_string_columns_to_symbols
    rule = Authorization::AuthorizationRule.new("current_role", [:read], :perms, :or, {:on_columns => "name"})
    assert_equal [:name], rule.accessible_columns
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
  
  def test_should_respond_to_has_permissions_to_columns
    rule = Authorization::AuthorizationRule.new("current_role")
    assert rule.respond_to?("has_permissions_to_columns"), "should have an has_permissions_to_columns method"
  end
  
  def test_should_check_if_the_columns_passed_in_match_accessible_ones
    rule = Authorization::AuthorizationRule.new("current_role", [:read], :perms, :or, {:on_columns => [:id, :title, :text]})
    assert_equal true, rule.has_permissions_to_columns([:id, :title, :text], {:column_check => true}), "Should have access to these columns"
    assert_equal false, rule.has_permissions_to_columns([:id, :title, :text, :admin_access], {:column_check => true}), "Should have NOT access to all these columns"
    assert_equal true, rule.has_permissions_to_columns([:id, :title], {:column_check => true}), "Should have access to these columns"
    assert_equal true, rule.has_permissions_to_columns([:id], {:column_check => true}), "Should have access to these columns"
    assert_equal true, rule.has_permissions_to_columns([:title, :text, :id], {:column_check => true}), "Should have access to these columns"
    assert_equal true, rule.has_permissions_to_columns([:text, :title, :id], {:column_check => true}), "Should have access to these columns"
    assert_equal false, rule.has_permissions_to_columns([:text, :title, :id, :admin_access], {:column_check => true}), "Should NOT have access to these columns"
    assert_equal true, rule.has_permissions_to_columns(["text", "title", "id"], {:column_check => true}), "Should have access to these columns"
    rule = Authorization::AuthorizationRule.new("current_role", [:read], :perms, :or, {:on_columns => ["id", "title", "text"]})
    assert_equal true, rule.has_permissions_to_columns([:text, :title, :id], {:column_check => true}), "Should have access to these columns"
  end
  
  
  def test_should_return_true_if_permission_by_pass_is_set
    rule = Authorization::AuthorizationRule.new("current_role", [:read], :perms, :or, {:on_columns => [:id, :title, :text]})
    assert_equal true, rule.has_permissions_to_columns([:id, :title, :text, :admin_access], {:column_check => false}), "should return true because bypass is set"
  end
  
  def test_should_return_true_if_both_bypasses_are_set_for_satisfies_attribute_conditions_and_columns_permissions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %|
      authorization do
        role :test_role do
          has_permission_on :perms, :to => :test, :on_columns => [:name]
        end
      end
    |
    engine = Authorization::Engine.new(reader)
    attr_validator = Authorization::Engine::AttributeValidator.new(engine, "user", Object, [:create, :read, :update, :delete], :context)
    #skip both validations
    options = {:skip_attribute_test => true, :column_check => false}
    assert_equal true, reader.auth_rules_reader.auth_rules.first.satisfies_attribute_conditions_and_columns_permissions(attr_validator, options), 
      "should always return true because of bypass settings"
  end

  def test_should_not_pass_satisfies_attribute_conditions_and_columns_permissions_because_attribute_check
    mock_object = LoadMockObject
    reader = Authorization::Reader::DSLReader.new
    reader.parse %|
      authorization do
        role :test_role do
          has_permission_on :perms, :to => :test do
            if_attribute :name => is {"LoadMockObject1"}
            on_columns [:name]
          end
        end
      end
    |
    engine = Authorization::Engine.new(reader)
    attr_validator = Authorization::Engine::AttributeValidator.new(engine, "user", mock_object, [:create, :read, :update, :delete], :context)
    #column_check is skipped, but attribute check fails because of LoadMockObject1 should be LoadMockObject
    options = {:column_check => false}
    assert_equal false, reader.auth_rules_reader.auth_rules.first.satisfies_attribute_conditions_and_columns_permissions(attr_validator, options), 
      "attribute check is being performed, which should fail so the method should fail"
  end
  

  def test_should_not_pass_satisfies_attribute_conditions_and_columns_permissions_because_column_check
    mock_object = LoadMockObject
    reader = Authorization::Reader::DSLReader.new
    reader.parse %|
      authorization do
        role :test_role do
          has_permission_on :perms, :to => :test do
            if_attribute :name => is {"LoadMockObject"}
            on_columns []
          end
        end
      end
    |
    engine = Authorization::Engine.new(reader)
    attr_validator = Authorization::Engine::AttributeValidator.new(engine, "user", mock_object, [:create, :read, :update, :delete], :context)
    #name column is being modified without permission
    options = {:columns => [:name], :column_check => true}
    assert_equal false, reader.auth_rules_reader.auth_rules.first.satisfies_attribute_conditions_and_columns_permissions(attr_validator, options), 
      "column check is being performed, which should fail so the method should fail"
  end
  
  
  
  
end
