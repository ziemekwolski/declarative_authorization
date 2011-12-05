$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "declarative_authorization/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "declarative_authorization"
  s.version     = DeclarativeAuthorization::VERSION
  s.authors     = ["Steffen Bartch"]
  s.email       = ["sbartsch@tzi.org"]
  s.homepage    = "http://github.com/stonefield/declarative_authorization"
  s.summary     = "declarative_authorization is a Rails plugin for maintainable authorization based on readable authorization rules."
  s.description = "DeclarativeAuthorization adapted for Rails 3.1."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc", "authorization_rules.dist.rb"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.1.3"

#  s.add_development_dependency "sqlite3"
end
