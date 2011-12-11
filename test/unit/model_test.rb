require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require File.join(File.dirname(__FILE__), '..', 'model_test_helper.rb')

class ModelTest < Test::Unit::TestCase
  def test_permit_with_has_one_raises_no_name_error
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do :test_attr_has_one
        role :test_role do
          has_permission_on :test_attrs, :to => :update do
            if_attribute :id => is { user.test_attr.id }
          end
        end
      end
    }
    instance = Authorization::Engine.instance(reader)
    
    test_model = TestModel.create!
    test_attr = test_model.create_test_attr_has_one
    assert !test_attr.new_record?
    
    user = MockUser.new(:test_role, :test_attr => test_attr)
    
    assert_nothing_raised do
      assert instance.permit?(:update, :user => user, :object => test_model.test_attr_has_one) 
    end
    
    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_model_security_write_allowed
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
            if_attribute :attr => is { 1 }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    Authorization.current_user = MockUser.new(:test_role)
    assert(object = TestModelSecurityModel.create)

    assert_nothing_raised { object.update_attributes(:attr_2 => 2) }
    object.reload
    assert_equal 2, object.attr_2
    object.destroy
    assert_raise ActiveRecord::RecordNotFound do
      TestModelSecurityModel.find(object.id)
    end
  end

  def test_model_security_write_not_allowed_no_privilege
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
            if_attribute :attr => is { 1 }
          end
        end
        role :test_role_restricted do
        end
      end
    }
    Authorization::Engine.instance(reader)

    Authorization.current_user = MockUser.new(:test_role)
    assert(object = TestModelSecurityModel.create)

    Authorization.current_user = MockUser.new(:test_role_restricted)
    assert_raise Authorization::NotAuthorized do
      object.update_attributes(:attr_2 => 2)
    end
  end
  
  def test_model_security_write_not_allowed_wrong_attribute_value
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role_unrestricted do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
          end
        end
        role :test_role do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
            if_attribute :attr => is { 1 }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    Authorization.current_user = MockUser.new(:test_role)
    assert(object = TestModelSecurityModel.create)
    assert_raise Authorization::AttributeAuthorizationError do
      TestModelSecurityModel.create :attr => 2
    end
    object = TestModelSecurityModel.create
    assert_raise Authorization::AttributeAuthorizationError do
      object.update_attributes(:attr => 2)
    end
    object.reload

    assert_nothing_raised do
      object.update_attributes(:attr_2 => 1)
    end
    assert_raise Authorization::AttributeAuthorizationError do
      object.update_attributes(:attr => 2)
    end
  end

  def test_model_security_with_and_without_find_restrictions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role_unrestricted do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
          end
        end
        role :test_role do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
            if_attribute :attr => is { 1 }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    Authorization.current_user = MockUser.new(:test_role_unrestricted)
    object = TestModelSecurityModel.create :attr => 2
    object_with_find = TestModelSecurityModelWithFind.create :attr => 2
    Authorization.current_user = MockUser.new(:test_role)
    assert_nothing_raised do
      object.class.find(object.id)
    end
    assert_raise Authorization::AttributeAuthorizationError do
      object_with_find.class.find(object_with_find.id)
    end
  end

  def test_model_security_with_read_restrictions_and_exists
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
            if_attribute :test_attr => is { user.test_attr }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_attr = TestAttr.create
    Authorization.current_user = MockUser.new(:test_role, :test_attr => test_attr)
    object_with_find = TestModelSecurityModelWithFind.create :test_attr => test_attr
    assert_nothing_raised do
      object_with_find.class.find(object_with_find.id)
    end
    assert_equal 1, test_attr.test_model_security_model_with_finds.length
    
    # Raises error since AR does not populate the object
    #assert test_attr.test_model_security_model_with_finds.exists?(object_with_find)
  end

  def test_model_security_delete_unallowed
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role_unrestricted do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
          end
        end
        role :test_role do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
            if_attribute :attr => is { 1 }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    Authorization.current_user = MockUser.new(:test_role_unrestricted)
    object = TestModelSecurityModel.create :attr => 2
    Authorization.current_user = MockUser.new(:test_role)

    assert_raise Authorization::AttributeAuthorizationError do
      object.destroy
    end
  end

  def test_model_security_changing_critical_attribute_unallowed
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role_unrestricted do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
          end
        end
        role :test_role do
          has_permission_on :test_model_security_models do
            to :read, :create, :update, :delete
            if_attribute :attr => is { 1 }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    Authorization.current_user = MockUser.new(:test_role_unrestricted)
    object = TestModelSecurityModel.create :attr => 2
    Authorization.current_user = MockUser.new(:test_role)

    # TODO before not checked yet
    #assert_raise Authorization::AuthorizationError do
    #  object.update_attributes(:attr => 1)
    #end
  end

  def test_model_security_no_role_unallowed
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
      end
    }
    Authorization::Engine.instance(reader)

    Authorization.current_user = MockUser.new(:test_role_2)
    assert_raise Authorization::NotAuthorized do
      TestModelSecurityModel.create
    end
  end

  def test_model_security_with_assoc
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_model_security_models do
            to :create, :update, :delete
            if_attribute :test_attrs => contains { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)
    
    test_attr = TestAttr.create
    test_attr.role_symbols << :test_role
    Authorization.current_user = test_attr
    assert(object = TestModelSecurityModel.create(:test_attrs => [test_attr]))
    assert_nothing_raised do
      object.update_attributes(:attr_2 => 2)
    end
    without_access_control do
      object.reload
    end
    assert_equal 2, object.attr_2 
    object.destroy
    assert_raise ActiveRecord::RecordNotFound do
      TestModelSecurityModel.find(object.id)
    end
  end

  def test_model_security_with_update_attrbributes
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_model_security_models, :to => :update do
            if_attribute :test_attrs => { :branch => is { user.branch }}
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    params = {
      :model_data => { :attr => 11 }
    }

    test_attr = TestAttr.create!(:branch => Branch.create!)
    test_model = without_access_control do
      TestModelSecurityModel.create!(:test_attrs => [test_attr])
    end

    with_user MockUser.new(:test_role, :branch => test_attr.branch) do
      assert_nothing_raised do
        test_model.update_attributes(params[:model_data])
      end
    end
    without_access_control do
      assert_equal params[:model_data][:attr], test_model.reload.attr
    end

    TestAttr.delete_all
    TestModelSecurityModel.delete_all
    Branch.delete_all
  end

  def test_using_access_control
    assert !TestModel.using_access_control?
    assert TestModelSecurityModel.using_access_control?
  end

  def test_authorization_permit_association_proxy
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => {:content => "content" }
          end
        end
      end
    }
    engine = Authorization::Engine.instance(reader)

    test_model = TestModel.create(:content => "content")
    assert engine.permit?(:read, :object => test_model.test_attrs,
                          :user => MockUser.new(:test_role))
    assert !engine.permit?(:read, :object => TestAttr.new,
                          :user => MockUser.new(:test_role))
    TestModel.delete_all
  end

  def test_multiple_roles_with_has_many_through
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role_1 do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attr_throughs => contains {user.test_attr_through_id},
                :content => 'test_1'
          end
        end

        role :test_role_2 do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attr_throughs_2 => contains {user.test_attr_through_2_id},
                :content => 'test_2'
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create! :content => 'test_1'
    test_model_2 = TestModel.create! :content => 'test_2'
    test_model_1.test_attrs.create!.test_attr_throughs.create!
    test_model_2.test_attrs.create!.test_attr_throughs.create!

    user = MockUser.new(:test_role_1, :test_role_2,
        :test_attr_through_id => test_model_1.test_attr_throughs.first.id,
        :test_attr_through_2_id => test_model_2.test_attr_throughs.first.id)
    assert_equal 2, TestModel.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
    TestAttr.delete_all
    TestAttrThrough.delete_all
  end

  def test_model_permitted_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :companies, :to => :read do
            if_attribute :name => "company_1"
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    user = MockUser.new(:test_role)
    allowed_read_company = Company.new(:name => 'company_1')
    prohibited_company = Company.new(:name => 'company_2')

    assert allowed_read_company.permitted_to?(:read, :user => user)
    assert !allowed_read_company.permitted_to?(:update, :user => user)
    assert !prohibited_company.permitted_to?(:read, :user => user)

    executed_block = false
    allowed_read_company.permitted_to?(:read, :user => user) do
      executed_block = true
    end
    assert executed_block

    executed_block = false
    prohibited_company.permitted_to?(:read, :user => user) do
      executed_block = true
    end
    assert !executed_block

    assert_nothing_raised do
      allowed_read_company.permitted_to!(:read, :user => user)
    end
    assert_raise Authorization::NotAuthorized do
      prohibited_company.permitted_to!(:update, :user => user)
    end
    assert_raise Authorization::AttributeAuthorizationError do
      prohibited_company.permitted_to!(:read, :user => user)
    end
  end

  def test_model_permitted_to_with_modified_context
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :companies, :to => :read
        end
      end
    }
    Authorization::Engine.instance(reader)

    user = MockUser.new(:test_role)
    allowed_read_company = SmallCompany.new(:name => 'small_company_1')

    assert allowed_read_company.permitted_to?(:read, :user => user)
    assert !allowed_read_company.permitted_to?(:update, :user => user)
  end
end
