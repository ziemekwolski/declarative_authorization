Declarative Authorization
==========================

This is a fork of the original, Declarative Authorization found here: https://github.com/stffn/declarative_authorization

This fork includes the following new additions:

Quick summary of what declarative_authorization does:

A programmer defines a set of permissions for their application.  For example:

config/authorization_rules.rb - DSL Definition

```ruby
authorization do
  role :admin do
    has_permission_on :employees, :to => [:create, :read, :update, :delete]
  end
end
```

In this case if the user wants to change anything about the employees object, then they need to be part of the "admin" role. This mostly suited for controller based permissions.

My patch adds the ability to set columns on those permissions.

```ruby
authorization do
  role :admin do
    has_permission_on :employees, :to => [:create, :read, :update, :delete], :on_columns => [:id, :name, :title]
  end
end
```

Model

```ruby
class Employee  < ActiveRecord::Base
  using_access_control({:column_check => true})
end
```

In this case a user with the admin role can only access the [:id, :name, :title] columns. If they try to modify say :salary then an exception is thrown.
This patch tries to preserve both the style and fundamental idea of how declarative authorization works.

Limitations:

1. No Automatic scoping. At this point there is no dynamic scoping which would force database to select what the current user has access to see. -- hopefully will be added in the next version.