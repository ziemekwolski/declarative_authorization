require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require File.join(File.dirname(__FILE__), '..', 'model_test_helper.rb')

class NamedScopeModelTest < Test::Unit::TestCase
  def test_multiple_deep_ored_belongs_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => {:test_attrs => contains {user}}
            if_attribute :test_another_model => {:test_attrs => contains {user}}
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_attr_1 = TestAttr.create! :test_model_id => test_model_1.id,
                      :test_another_model_id => test_model_2.id

    user = MockUser.new(:test_role, :id => test_attr_1)
    assert_equal 1, TestAttr.with_permissions_to(:read, :user => user).length
    TestAttr.delete_all
    TestModel.delete_all
  end

  def test_with_belongs_to_and_has_many_with_contains
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => { :test_attrs => contains { user.test_attr_value } }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_attr_1 = TestAttr.create!
    test_model_1 = TestModel.create!
    test_model_1.test_attrs.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.test_attrs.first.id )
    assert_equal 1, TestAttr.with_permissions_to( :read, :context => :test_attrs, :user => user ).length
    assert_equal 1, TestAttr.with_permissions_to( :read, :user => user ).length
    assert_raise Authorization::NotAuthorized do
      TestAttr.with_permissions_to( :update_test_attrs, :user => user )
    end
    TestAttr.delete_all
    TestModel.delete_all
  end

  def test_with_nested_has_many
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :companies, :to => :read do
            if_attribute :branches => { :test_attrs => { :attr => is { user.test_attr_value } } }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    allowed_company = Company.create!
    allowed_company.branches.create!.test_attrs.create!(:attr => 1)
    allowed_company.branches.create!.test_attrs.create!(:attr => 2)

    prohibited_company = Company.create!
    prohibited_company.branches.create!.test_attrs.create!(:attr => 3)

    user = MockUser.new(:test_role, :test_attr_value => 1)
    prohibited_user = MockUser.new(:test_role, :test_attr_value => 4)
    assert_equal 1, Company.with_permissions_to(:read, :user => user).length
    assert_equal 0, Company.with_permissions_to(:read, :user => prohibited_user).length

    Company.delete_all
    Branch.delete_all
    TestAttr.delete_all
  end

  def test_with_nested_has_many_through
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attr_throughs => { :test_attr => { :attr => is { user.test_attr_value } } }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    allowed_model = TestModel.create!
    allowed_model.test_attrs.create!(:attr => 1).test_attr_throughs.create!
    allowed_model.test_attrs.create!(:attr => 2).test_attr_throughs.create!

    prohibited_model = TestModel.create!
    prohibited_model.test_attrs.create!(:attr => 3).test_attr_throughs.create!

    user = MockUser.new(:test_role, :test_attr_value => 1)
    prohibited_user = MockUser.new(:test_role, :test_attr_value => 4)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_equal 0, TestModel.with_permissions_to(:read, :user => prohibited_user).length

    TestModel.delete_all
    TestAttrThrough.delete_all
    TestAttr.delete_all
  end

  def test_with_is
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 1, TestModel.with_permissions_to(:read,
      :context => :test_models, :user => user).length
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_raise Authorization::NotAuthorized do
      TestModel.with_permissions_to(:update_test_models, :user => user)
    end
    TestModel.delete_all
  end

  def test_named_scope_on_proxy
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_attrs.create!
    test_model_1.test_attrs.create!
    TestAttr.create!

    user = MockUser.new(:test_role, :test_attr_value => test_attr_1.id)
    assert_equal 1, test_model_1.test_attrs.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_named_scope_on_named_scope
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attr_through_id => 1
          end
          has_permission_on :test_attrs, :to => :read do
            if_permitted_to :read, :test_model
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    country = Country.create!
    model_1 = TestModel.create!(:test_attr_through_id => 1, :content => "Content")
    country.test_models << model_1
    TestModel.create!(:test_attr_through_id => 1)
    TestModel.create!(:test_attr_through_id => 2, :content => "Content")

    user = MockUser.new(:test_role)

    # TODO implement query_count for Rails 3
    TestModel.query_count = 0
    assert_equal 2, TestModel.with_permissions_to(:read, :user => user).length
    assert_equal 1, TestModel.query_count if Rails.version < "3"

    TestModel.query_count = 0
    assert_equal 1, TestModel.with_content.with_permissions_to(:read, :user => user).length
    assert_equal 1, TestModel.query_count if Rails.version < "3"

    TestModel.query_count = 0
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).with_content.length
    assert_equal 1, TestModel.query_count if Rails.version < "3"

    TestModel.query_count = 0
    assert_equal 1, country.test_models.with_permissions_to(:read, :user => user).length
    assert_equal 1, TestModel.query_count if Rails.version < "3"

    TestModel.delete_all
    Country.delete_all
  end

  def test_with_modified_context
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :companies, :to => :read do
            if_attribute :id => is { user.test_company_id }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_company = SmallCompany.create!

    user = MockUser.new(:test_role, :test_company_id => test_company.id)
    assert_equal 1, SmallCompany.with_permissions_to(:read,
      :user => user).length
    SmallCompany.delete_all
  end

  def test_with_is_nil
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :content => nil
          end
        end
        role :test_role_not_nil do
          has_permission_on :test_models, :to => :read do
            if_attribute :content => is_not { nil }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create! :content => "Content"

    assert_equal test_model_1, TestModel.with_permissions_to(:read,
      :context => :test_models, :user => MockUser.new(:test_role)).first
    assert_equal test_model_2, TestModel.with_permissions_to(:read,
      :context => :test_models, :user => MockUser.new(:test_role_not_nil)).first
    TestModel.delete_all
  end

  def test_with_not_is
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is_not { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
  end

  def test_with_lt
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => lt { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id + 1)
    assert_equal 1, TestModel.with_permissions_to(:read,
      :context => :test_models, :user => user).length
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_raise Authorization::NotAuthorized do
      TestModel.with_permissions_to(:update_test_models, :user => user)
    end
    TestModel.delete_all
  end

  def test_with_lte
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => lte { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    2.times { TestModel.create! }

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id + 1)
    assert_equal 2, TestModel.with_permissions_to(:read,
      :context => :test_models, :user => user).length
    assert_equal 2, TestModel.with_permissions_to(:read, :user => user).length
    assert_raise Authorization::NotAuthorized do
      TestModel.with_permissions_to(:update_test_models, :user => user)
    end
    TestModel.delete_all
  end

  def test_with_gt
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => gt { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    TestModel.create!
    test_model_1 = TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id - 1)
    assert_equal 1, TestModel.with_permissions_to(:read,
      :context => :test_models, :user => user).length
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_raise Authorization::NotAuthorized do
      TestModel.with_permissions_to(:update_test_models, :user => user)
    end
    TestModel.delete_all
  end

  def test_with_gte
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => gte { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    2.times { TestModel.create! }
    test_model_1 = TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id - 1)
    assert_equal 2, TestModel.with_permissions_to(:read,
      :context => :test_models, :user => user).length
    assert_equal 2, TestModel.with_permissions_to(:read, :user => user).length
    assert_raise Authorization::NotAuthorized do
      TestModel.with_permissions_to(:update_test_models, :user => user)
    end
    TestModel.delete_all
  end

  def test_with_empty_obligations
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read
        end
      end
    }
    Authorization::Engine.instance(reader)

    TestModel.create!

    user = MockUser.new(:test_role)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_raise Authorization::NotAuthorized do
      TestModel.with_permissions_to(:update, :user => user)
    end
    TestModel.delete_all
  end

  def test_multiple_obligations
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value_2 }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id,
                        :test_attr_value_2 => test_model_2.id)
    assert_equal 2, TestModel.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
  end

  def test_multiple_roles
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :attr => [1,2]
          end
        end

        role :test_role_2 do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :attr => [2,3]
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    TestAttr.create! :attr => 1
    TestAttr.create! :attr => 2
    TestAttr.create! :attr => 3

    user = MockUser.new(:test_role)
    assert_equal 2, TestAttr.with_permissions_to(:read, :user => user).length
    TestAttr.delete_all
  end

  def test_multiple_and_empty_obligations
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
          has_permission_on :test_models, :to => :read
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 2, TestModel.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
  end

  def test_multiple_attributes
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }, :content => "bla"
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create! :content => 'bla'
    TestModel.create! :content => 'bla'
    TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
  end

  def test_multiple_belongs_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => is {user}
            if_attribute :test_another_model => is {user}
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_attr_1 = TestAttr.create! :test_model_id => 1, :test_another_model_id => 2

    user = MockUser.new(:test_role, :id => 1)
    assert_equal 1, TestAttr.with_permissions_to(:read, :user => user).length
    TestAttr.delete_all
  end

  def test_with_is_and_priv_hierarchy
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      privileges do
        privilege :read do
          includes :list, :show
        end
      end
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :id => is { user.test_attr_value }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    TestModel.create!

    user = MockUser.new(:test_role, :test_attr_value => test_model_1.id)
    assert_equal 1, TestModel.with_permissions_to(:list,
      :context => :test_models, :user => user).length
    assert_equal 1, TestModel.with_permissions_to(:list, :user => user).length

    TestModel.delete_all
  end

  def test_with_is_and_belongs_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => is { user.test_model }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!

    user = MockUser.new(:test_role, :test_model => test_model_1)
    assert_equal 1, TestAttr.with_permissions_to(:read,
      :context => :test_attrs, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_deep_attribute
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => {:id => is { user.test_model_id } }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!

    user = MockUser.new(:test_role, :test_model_id => test_model_1.id)
    assert_equal 1, TestAttr.with_permissions_to(:read,
      :context => :test_attrs, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_anded_rules
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read, :join_by => :and do
            if_attribute :test_model => is { user.test_model }
            if_attribute :attr => 1
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_1.test_attrs.create!(:attr => 1)
    TestModel.create!.test_attrs.create!(:attr => 1)
    TestModel.create!.test_attrs.create!

    user = MockUser.new(:test_role, :test_model => test_model_1)
    assert_equal 1, TestAttr.with_permissions_to(:read,
      :context => :test_attrs, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_contains
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs => contains { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!
    test_model_1.test_attrs.create!
    test_model_2.test_attrs.create!

    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attrs.first.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).find(:all, :conditions => {:id => test_model_1.id}).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_does_not_contain
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs => does_not_contain { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!
    test_model_2.test_attrs.create!

    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attrs.first.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_contains_conditions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs_with_attr => contains { user }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs_with_attr.create!
    test_model_1.test_attrs.create!(:attr => 2)
    test_model_2.test_attrs_with_attr.create!
    test_model_2.test_attrs.create!(:attr => 2)

    #assert_equal 1, test_model_1.test_attrs_with_attr.length
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attrs.first.id)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    user = MockUser.new(:test_role,
                        :id => test_model_1.test_attrs.last.id)
    assert_equal 0, TestModel.with_permissions_to(:read, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  # TODO fails in Rails 3 because TestModel.scoped.joins(:test_attr_throughs_with_attr)
  # does not work
  if Rails.version < "3"
    def test_with_contains_through_conditions
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :test_models, :to => :read do
              if_attribute :test_attr_throughs_with_attr => contains { user }
            end
          end
        end
      }
      Authorization::Engine.instance(reader)

      test_model_1 = TestModel.create!
      test_model_2 = TestModel.create!
      test_model_1.test_attrs.create!(:attr => 1).test_attr_throughs.create!
      test_model_1.test_attrs.create!(:attr => 2).test_attr_throughs.create!
      test_model_2.test_attrs.create!(:attr => 1).test_attr_throughs.create!
      test_model_2.test_attrs.create!(:attr => 2).test_attr_throughs.create!

      #assert_equal 1, test_model_1.test_attrs_with_attr.length
      user = MockUser.new(:test_role,
                          :id => test_model_1.test_attr_throughs.first.id)
      assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
      user = MockUser.new(:test_role,
                          :id => test_model_1.test_attr_throughs.last.id)
      assert_equal 0, TestModel.with_permissions_to(:read, :user => user).length

      TestModel.delete_all
      TestAttrThrough.delete_all
      TestAttr.delete_all
    end
  end

  if Rails.version < "3"
    def test_with_contains_habtm
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :test_models, :to => :read do
              if_attribute :test_attr_throughs_habtm => contains { user.test_attr_through_id }
            end
          end
        end
      }
      Authorization::Engine.instance(reader)

      # TODO habtm currently not working in Rails 3
      test_model_1 = TestModel.create!
      test_model_2 = TestModel.create!
      test_attr_through_1 = TestAttrThrough.create!
      test_attr_through_2 = TestAttrThrough.create!
      TestAttr.create! :test_model_id => test_model_1.id, :test_attr_through_id => test_attr_through_1.id
      TestAttr.create! :test_model_id => test_model_2.id, :test_attr_through_id => test_attr_through_2.id

      user = MockUser.new(:test_role,
                          :test_attr_through_id => test_model_1.test_attr_throughs_habtm.first.id)
      assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
      assert_equal test_model_1, TestModel.with_permissions_to(:read, :user => user)[0]

      TestModel.delete_all
      TestAttrThrough.delete_all
      TestAttr.delete_all
    end
  end

  # :primary_key not available in Rails prior to 2.2
  if Rails.version > "2.2"
    def test_with_contains_through_primary_key
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :test_models, :to => :read do
              if_attribute :test_attr_throughs_with_primary_id => contains { user }
            end
          end
        end
      }
      Authorization::Engine.instance(reader)

      test_attr_through_1 = TestAttrThrough.create!
      test_item = NWayJoinItem.create!
      test_model_1 = TestModel.create!(:test_attr_through_id => test_attr_through_1.id)
      test_attr_1 = TestAttr.create!(:test_attr_through_id => test_attr_through_1.id,
          :n_way_join_item_id => test_item.id)

      user = MockUser.new(:test_role,
                          :id => test_attr_through_1.id)
      assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length

      TestModel.delete_all
      TestAttrThrough.delete_all
      TestAttr.delete_all
    end
  end

  def test_with_intersects_with
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs => intersects_with { user.test_attrs }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!
    test_model_1.test_attrs.create!
    test_model_1.test_attrs.create!
    test_model_2.test_attrs.create!

    user = MockUser.new(:test_role,
                        :test_attrs => [test_model_1.test_attrs.first, TestAttr.create!])
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length

    user = MockUser.new(:test_role,
                        :test_attrs => [TestAttr.create!])
    assert_equal 0, TestModel.with_permissions_to(:read, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_is_and_has_one
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do :test_attr_has_one
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attr_has_one => is { user.test_attr }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!

    user = MockUser.new(:test_role, :test_attr => test_attr_1)
    assert_equal 1, TestModel.with_permissions_to(:read,
      :context => :test_models, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  # TODO fails in Rails 3 because TestModel.scoped.joins(:test_attr_throughs_with_attr)
  # does not work
  if Rails.version < "3"
    def test_with_is_and_has_one_through_conditions
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :test_models, :to => :read do
              if_attribute :test_attr_throughs_with_attr_and_has_one => is { user }
            end
          end
        end
      }
      Authorization::Engine.instance(reader)

      test_model_1 = TestModel.create!
      test_model_2 = TestModel.create!
      test_model_1.test_attrs.create!(:attr => 1).test_attr_throughs.create!
      test_model_1.test_attrs.create!(:attr => 2).test_attr_throughs.create!
      test_model_2.test_attrs.create!(:attr => 1).test_attr_throughs.create!
      test_model_2.test_attrs.create!(:attr => 2).test_attr_throughs.create!

      #assert_equal 1, test_model_1.test_attrs_with_attr.length
      user = MockUser.new(:test_role,
                          :id => test_model_1.test_attr_throughs.first.id)
      assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
      user = MockUser.new(:test_role,
                          :id => test_model_1.test_attr_throughs.last.id)
      assert_equal 0, TestModel.with_permissions_to(:read, :user => user).length

      TestModel.delete_all
      TestAttr.delete_all
      TestAttrThrough.delete_all
    end
  end

  def test_with_is_in
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => is_in { [user.test_model, user.test_model_2] }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!

    user = MockUser.new(:test_role, :test_model => test_model_1,
      :test_model_2 => test_model_2)
    assert_equal 1, TestAttr.with_permissions_to(:read,
      :context => :test_attrs, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_not_is_in
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_model => is_not_in { [user.test_model, user.test_model_2] }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_model_2 = TestModel.create!
    test_model_1.test_attrs.create!
    TestModel.create!.test_attrs.create!

    user = MockUser.new(:test_role, :test_model => test_model_1,
      :test_model_2 => test_model_2)
    assert_equal 1, TestAttr.with_permissions_to(:read,
      :context => :test_attrs, :user => user).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_if_permitted_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs => contains { user }
          end
          has_permission_on :test_attrs, :to => :read do
            if_permitted_to :read, :test_model
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_attrs.create!

    user = MockUser.new(:test_role, :id => test_attr_1.id)
    assert_equal 1, TestAttr.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_anded_if_permitted_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :base_role do
          has_permission_on :test_attrs, :to => :read, :join_by => :and do
            if_permitted_to :read, :test_model
            if_attribute :attr => 1
          end
        end
        role :first_role do
          includes :base_role
          has_permission_on :test_models, :to => :read do
            if_attribute :content => "first test"
          end
        end
        role :second_role do
          includes :base_role
          has_permission_on :test_models, :to => :read do
            if_attribute :country_id => 2
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!(:content => "first test")
    test_model_1.test_attrs.create!(:attr => 1)
    test_model_for_second_role = TestModel.create!(:country_id => 2)
    test_model_for_second_role.test_attrs.create!(:attr => 1)
    test_model_for_second_role.test_attrs.create!(:attr => 2)

    user = MockUser.new(:first_role)
    assert Authorization::Engine.instance.permit?(:read, :object => test_model_1.test_attrs.first, :user => user)
    assert_equal 1, TestAttr.with_permissions_to(:read, :user => user).length

    user_with_both_roles = MockUser.new(:first_role, :second_role)
    assert Authorization::Engine.instance.permit?(:read, :object => test_model_1.test_attrs.first, :user => user_with_both_roles)
    assert Authorization::Engine.instance.permit?(:read, :object => test_model_for_second_role.test_attrs.first, :user => user_with_both_roles)
    #p Authorization::Engine.instance.obligations(:read, :user => user_with_both_roles, :context => :test_attrs)
    assert_equal 2, TestAttr.with_permissions_to(:read, :user => user_with_both_roles).length

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_if_permitted_to_with_no_child_permissions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :another_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs => contains { user }
          end
        end
        role :additional_if_attribute do
          has_permission_on :test_attrs, :to => :read do
            if_permitted_to :read, :test_model
            if_attribute :test_model => {:test_attrs => contains { user }}
          end
        end
        role :only_permitted_to do
          has_permission_on :test_attrs, :to => :read do
            if_permitted_to :read, :test_model
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_attrs.create!

    user = MockUser.new(:only_permitted_to, :another_role, :id => test_attr_1.id)
    also_allowed_user = MockUser.new(:additional_if_attribute, :id => test_attr_1.id)
    non_allowed_user = MockUser.new(:only_permitted_to, :id => test_attr_1.id)

    assert_equal 1, TestAttr.with_permissions_to(:read, :user => user).length
    assert_equal 1, TestAttr.with_permissions_to(:read, :user => also_allowed_user).length
    assert_raise Authorization::NotAuthorized do
      TestAttr.with_permissions_to(:read, :user => non_allowed_user).find(:all)
    end

    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_if_permitted_to_with_context_from_model
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_another_attrs => contains { user }
          end
          has_permission_on :test_attrs, :to => :read do
            if_permitted_to :read, :test_another_model
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_another_attrs.create!

    user = MockUser.new(:test_role, :id => test_attr_1.id)
    non_allowed_user = MockUser.new(:test_role, :id => 111)

    assert_equal 1, TestAttr.with_permissions_to(:read, :user => user).length
    assert_equal 0, TestAttr.with_permissions_to(:read, :user => non_allowed_user).length
    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_has_many_if_permitted_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_permitted_to :read, :test_attrs
          end
          has_permission_on :test_attrs, :to => :read do
            if_attribute :attr => is { user.id }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_attrs.create!(:attr => 111)

    user = MockUser.new(:test_role, :id => test_attr_1.attr)
    non_allowed_user = MockUser.new(:test_role, :id => 333)
    assert_equal 1, TestModel.with_permissions_to(:read, :user => user).length
    assert_equal 0, TestModel.with_permissions_to(:read, :user => non_allowed_user).length
    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_deep_has_many_if_permitted_to
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :branches, :to => :read do
            if_attribute :name => "A Branch"
          end
          has_permission_on :companies, :to => :read do
            if_permitted_to :read, :test_attrs => :branch
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    readable_company = Company.create!
    readable_company.test_attrs.create!(:branch => Branch.create!(:name => "A Branch"))

    forbidden_company = Company.create!
    forbidden_company.test_attrs.create!(:branch => Branch.create!(:name => "Different Branch"))

    user = MockUser.new(:test_role)
    assert_equal 1, Company.with_permissions_to(:read, :user => user).length
    Company.delete_all
    Branch.delete_all
    TestAttr.delete_all
  end

  def test_with_if_permitted_to_and_empty_obligations
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read
          has_permission_on :test_attrs, :to => :read do
            if_permitted_to :read, :test_model
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_attrs.create!

    user = MockUser.new(:test_role)
    assert_equal 1, TestAttr.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_if_permitted_to_nil
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs => contains { user }
          end
          has_permission_on :test_attrs, :to => :read do
            if_permitted_to :read, :test_model
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_attr_1 = TestAttr.create!

    user = MockUser.new(:test_role, :id => test_attr_1.id)
    assert_equal 0, TestAttr.with_permissions_to(:read, :user => user).length
    TestAttr.delete_all
  end

  def test_with_if_permitted_to_self
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_models, :to => :read do
            if_attribute :test_attrs => contains { user }
          end
          has_permission_on :test_models, :to => :update do
            if_permitted_to :read
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_model_1 = TestModel.create!
    test_attr_1 = test_model_1.test_attrs.create!
    test_attr_2 = TestAttr.create!

    user = MockUser.new(:test_role, :id => test_attr_1.id)
    assert_equal 1, TestModel.with_permissions_to(:update, :user => user).length
    TestAttr.delete_all
    TestModel.delete_all
  end

  def test_with_has_many_and_reoccuring_tables
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_another_model => { :content => 'test_1_2' },
                :test_model => { :content => 'test_1_1' }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_attr_1 = TestAttr.create!(
        :test_model => TestModel.create!(:content => 'test_1_1'),
        :test_another_model => TestModel.create!(:content => 'test_1_2')
      )
    test_attr_2 = TestAttr.create!(
        :test_model => TestModel.create!(:content => 'test_2_1'),
        :test_another_model => TestModel.create!(:content => 'test_2_2')
      )

    user = MockUser.new(:test_role)
    assert_equal 1, TestAttr.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_ored_rules_and_reoccuring_tables
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_another_model => { :content => 'test_1_2' },
                :test_model => { :content => 'test_1_1' }
          end
          has_permission_on :test_attrs, :to => :read do
            if_attribute :test_another_model => { :content => 'test_2_2' },
                :test_model => { :test_attrs => contains {user.test_attr} }
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    test_attr_1 = TestAttr.create!(
        :test_model => TestModel.create!(:content => 'test_1_1'),
        :test_another_model => TestModel.create!(:content => 'test_1_2')
      )
    test_attr_2 = TestAttr.create!(
        :test_model => TestModel.create!(:content => 'test_2_1'),
        :test_another_model => TestModel.create!(:content => 'test_2_2')
      )
    test_attr_2.test_model.test_attrs.create!

    user = MockUser.new(:test_role, :test_attr => test_attr_2.test_model.test_attrs.last)
    assert_equal 2, TestAttr.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
    TestAttr.delete_all
  end

  def test_with_many_ored_rules_and_reoccuring_tables
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :test_attrs, :to => :read do
            if_attribute :branch => { :company => { :country => {
                :test_models => contains { user.test_model }
              }} }
            if_attribute :company => { :country => {
                :test_models => contains { user.test_model }
              }}
          end
        end
      end
    }
    Authorization::Engine.instance(reader)

    country = Country.create!(:name => 'country_1')
    country.test_models.create!
    test_attr_1 = TestAttr.create!(
        :branch => Branch.create!(:name => 'branch_1',
            :company => Company.create!(:name => 'company_1',
                :country => country))
      )
    test_attr_2 = TestAttr.create!(
        :company => Company.create!(:name => 'company_2',
            :country => country)
      )

    user = MockUser.new(:test_role, :test_model => country.test_models.first)

    assert_equal 2, TestAttr.with_permissions_to(:read, :user => user).length
    TestModel.delete_all
    TestAttr.delete_all
  end
end