class TestModel < ActiveRecord::Base
  has_many :test_attrs
  has_many :test_another_attrs, :class_name => "TestAttr", :foreign_key => :test_another_model_id
  has_many :test_attr_throughs, :through => :test_attrs
  has_many :test_attrs_with_attr, :class_name => "TestAttr", :conditions => {:attr => 1}
  has_many :test_attr_throughs_with_attr, :through => :test_attrs, 
    :class_name => "TestAttrThrough", :source => :test_attr_throughs,
    :conditions => "test_attrs.attr = 1"
  has_one :test_attr_has_one, :class_name => "TestAttr"
  has_one :test_attr_throughs_with_attr_and_has_one, :through => :test_attrs,
    :class_name => "TestAttrThrough", :source => :test_attr_throughs,
    :conditions => "test_attrs.attr = 1"

  # TODO currently not working in Rails 3
  if Rails.version < "3"
    has_and_belongs_to_many :test_attr_throughs_habtm, :join_table => :test_attrs,
        :class_name => "TestAttrThrough"
  end

  if Rails.version < "3"
    named_scope :with_content, :conditions => "test_models.content IS NOT NULL"
  else
    scope :with_content, :conditions => "test_models.content IS NOT NULL"
  end

  # Primary key test
  # :primary_key only available from Rails 2.2
  unless Rails.version < "2.2"
    has_many :test_attrs_with_primary_id, :class_name => "TestAttr",
      :primary_key => :test_attr_through_id, :foreign_key => :test_attr_through_id
    has_many :test_attr_throughs_with_primary_id, 
      :through => :test_attrs_with_primary_id, :class_name => "TestAttrThrough",
      :source => :n_way_join_item
  end

  # for checking for unnecessary queries
  mattr_accessor :query_count
  def self.find(*args)
    self.query_count ||= 0
    self.query_count += 1
    super(*args)
  end
end
