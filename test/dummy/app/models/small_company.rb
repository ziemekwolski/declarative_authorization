class SmallCompany < Company
  def self.decl_auth_context
    :companies
  end
end
