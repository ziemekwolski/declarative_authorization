class Country < ActiveRecord::Base
  has_many :test_models
  has_many :companies
end
