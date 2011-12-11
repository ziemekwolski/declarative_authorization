class Branch < ActiveRecord::Base
  has_many :test_attrs
  belongs_to :company
end
