class TestModelSecurityModelWithFind < ActiveRecord::Base
  set_table_name "test_model_security_models"
  has_many :test_attrs
  belongs_to :test_attr
  using_access_control :include_read => true, 
    :context => :test_model_security_models
end
