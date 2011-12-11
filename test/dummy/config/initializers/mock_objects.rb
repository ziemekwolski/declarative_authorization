class MockDataObject
  def initialize (attrs = {})
    attrs.each do |key, value|
      instance_variable_set(:"@#{key}", value)
      self.class.class_eval do
        attr_reader key
      end
    end
  end
  
  def self.descends_from_active_record?
    true
  end

  def self.table_name
    name.tableize
  end

  def self.name
    "Mock"
  end
  
  def self.find(*args)
    raise StandardError, "Couldn't find #{self.name} with id #{args[0].inspect}" unless args[0]
    new :id => args[0]
  end
end

class LoadMockObject < MockDataObject
  def self.name
    "LoadMockObject"
  end
end

class MockUser < MockDataObject
  def initialize (*roles)
    options = roles.last.is_a?(::Hash) ? roles.pop : {}
    super({:role_symbols => roles, :login => hash}.merge(options))
  end

  def initialize_copy (other)
    @role_symbols = @role_symbols.clone
  end
end


