class Company < ActiveRecord::Base
  has_many :test_attrs
  has_many :branches
  belongs_to :country
end
