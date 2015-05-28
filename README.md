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

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/inversion_of_control/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
