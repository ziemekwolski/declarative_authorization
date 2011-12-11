class TestModelSecurityModel < ActiveRecord::Base
  has_many :test_attrs
  using_access_control
end
