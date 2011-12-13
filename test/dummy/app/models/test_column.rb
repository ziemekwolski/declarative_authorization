class TestColumn < ActiveRecord::Base
  belongs_to :test_model
  belongs_to :test_another_model, :class_name => "TestModel", :foreign_key => :test_another_model_id
  belongs_to :test_a_third_model, :class_name => "TestModel", :foreign_key => :test_a_third_model_id
  belongs_to :n_way_join_item
  belongs_to :test_attr
  belongs_to :branch
  belongs_to :company
  has_many :test_attr_throughs
  has_many :test_model_security_model_with_finds
  attr_reader :role_symbols
  def initialize (*args)
    @role_symbols = []
    super(*args)
  end
  
  using_access_control({:column_check => true})
end
