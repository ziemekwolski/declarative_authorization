class NWayJoinItem < ActiveRecord::Base
  has_many :test_attrs
  has_many :others, :through => :test_attrs, :source => :n_way_join_item
end
