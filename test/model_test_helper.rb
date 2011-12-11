class ModelTestHelper
  class << self
    def setup_connection
      @connected ||= false
      return if @connected
      options = {:adapter => 'sqlite3', :timeout => 500, :database => ':memory:'}
      ActiveRecord::Base.establish_connection(options)
      ActiveRecord::Base.configurations = { 'sqlite3_ar_integration' => options }
      ActiveRecord::Base.connection

      File.read(File.join(File.dirname(__FILE__), "schema.sql")).split(';').each do |sql|
        ActiveRecord::Base.connection.execute(sql) unless sql.blank?
      end
      @connected = true
    end
  end
end

ModelTestHelper.setup_connection