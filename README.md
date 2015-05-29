# InversionOfControl

Dependency Injection is a powerful design pattern which can be utilised to help build loosely coupled and maintainable code. This pattern is quite commonly used for dependencies between services.

When the dependencies themselves become non-trivial though, it can become difficult to construct an object without also knowing how to inject it's dependencies. The coupling has been shifted from one side of the dependency to the other.

Using an Inversion of Control container it's possible to alleviate this problem by moving the responsibility of injecting the dependency to the IOC container.

This has other benefits such as being able to swap out implementations of a dependency at the container level without having to change the dependency itself or classes that depend on it.

The InversionOfControl gem brings an easy to configure IOC container while keeping your code boiler-plate free by utilising a simple DSL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'inversion_of_control'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install inversion_of_control

## Usage

###Configuring the container and registering dependencies

Dependencies that are to be injected must be registered up-front. A symbol which represents the name of the dependency will used to identify it later for injection.

A registered dependency can be any kind of object.

```
InversionOfControl.configure do |config|
  config.dependencies[:mail_service] = Mailgun::Client.new("your-api-key")
  config.dependencies[:user_repository] = UserRepository
end
```

To configure how a dependency is injected it can be wrapped in a hash.

```
InversionOfControl.configure do |config|
  config.dependencies[:user_repository] = {
    dependency: UserRepository,
    instantiate: false
  }
end
```

Registering a hash requires the dependency to be wrapped in configuration.

```
InversionOfControl.configure do |config|
  config.dependencies[:config] = {
    dependency: {foo: "bar"}
  }
end
```

###Injecting dependencies

Include the `InversionOfControl` module to classes that have dependencies. This adds a `.build` method to the class to be used in place of `.new`.

When using `.build`, dependencies will be automatically injected and an `attr_accessor` for each dependency is also created.

Alternatively calling `.new` and then `.inject_dependencies` will have the same result which can be used when you are not control of the instantiation of the class.

It should be noted that dependencies are not available during the `initialization` method on the class. The injection happens immediately afterwards or when manually called.

```
class MyClass
  include InversionOfControl
  inject(:user_repository, :mail_service)

  def email_user
    user = user_repository.find_user
    mail_service.send_email(user)
  end
end

MyClass.build
```

###instantiate_dependencies

If you are registering multiple classes which need to be instantiated upon injection the `instantiate_dependencies` configuration flag can be set to true (off by default). This will by default attempt to instantiate any dependency that is a Class.

If the dependency itself includes the `InversionOfControl` module it will use the `.build` method so that further dependencies can be resolved.

**Manual configuration**
```
InversionOfControl.configure do |config|
  config.instantiate_dependencies = true
  config.dependencies[:thing] = {
    dependency: EmailService,
    instantiate: true
  }
end
```

**Using instantiate_dependencies**
```
InversionOfControl.configure do |config|
  config.instantiate_dependencies = true
  config.dependencies[:thing] = EmailService
end
```

###auto register

When injecting a dependency that has not been registered, by default an "un-registered dependency" exception will be raised.

By turning on the `auto_resolve_unregistered_dependency` config option, the InversionOfControl container will attempt to locate the dependency by it's name. The current implementation attempts to find a Class with same name of the dependency.

**results of an auto-resolve**
```
:my_dependency => MyDependency
:user => User
```

###registering dependencies at runtime

Sometimes you might not be able to register a dependency at startup, or you need to change an already registered dependency at run-time.

A use-case for this would be when writing tests and you want to change dependencies for different test contexts.

```
InversionOfControl.register_dependency(:mail_service, MailChimp)
```

You can also register multiple dependencies at once

```
InversionOfControl.register_dependencies(
  mail_service: MailChimp,
  user_repository: LDAP
)
```

###Overriding dependencies

It is possible to override the dependencies injected when using the `.build` method. This is acheived by providing additional keyword arguments for the dependencies.

This does not interfere with the arguments of the initialize method which are passed through as normal without the dependencies.

```
class MyClass
  include InversionOfControl
  inject(:user_repository, :mail_service)

  def initialize(param_1, keyword_1:)
  end

  def email_user
    user = user_repository.find_user
    mail_service.send_email(user)
  end
end

MyClass.build("param_1", keyword_1: "keyword_1", mail_service: MailChimp)
```

At any point after the class has been instantiated dependencies can be re-injected. To override an already injected dependency the instance method `#.inject_dependency` can be called.

**inject single dependency**
```
my_instance = MyClass.build
my_isntance.inject_dependency(:mail_service, MailChimp)

```

**inject multiple dependencies**
```
my_instance = MyClass.build

my_isntance.inject_dependencies(
  mail_service: MailChimp,
  user_repository: LDAP
)
```

**inject the default dependencies**
```
my_instance = MyClass.build
my_isntance.inject_dependencies
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/inversion_of_control/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
