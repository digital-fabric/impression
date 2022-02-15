<h1 align="center">
  Impression
</h1>

<h4 align="center">A modern web framework for Ruby</h4>

<p align="center">
  <a href="http://rubygems.org/gems/impression">
    <img src="https://badge.fury.io/rb/impression.svg" alt="Ruby gem">
  </a>
  <a href="https://github.com/digital-fabric/impression/actions?query=workflow%3ATests">
    <img src="https://github.com/digital-fabric/impression/workflows/Tests/badge.svg" alt="Tests">
  </a>
  <a href="https://github.com/digital-fabric/impression/blob/master/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
  </a>
</p>

## What is Impression

> Impression is still in a very early stage of development. Things might not
> work correctly.

Impression is a modern web framework for Ruby. Unlike other web framework,
Impression does not impose any rigid structure or paradigm, but instead provides
a minimalistic set of tools, letting you build any kind of web app, by freely
mixing different kinds of web resources, be they static files, structured
templates, Jamstack sites, or dynamic APIs.

## Resources

The main abstraction in Impression is the resource - which represents an web
endpoint that is mounted at a specific location in the URL namespace, and
responds to requests. Resources can be nested in order to create arbitrarily
complex routing trees. Impression provides multiple resource types, each
customized for a specific use case, be it a JSON API, a set of MVC-style
controllers, or a Markdown-based blog with static content.

Finally, any kind of resource can be used as an Impression app. Routing is
performed automatically according to the resource tree, starting from the root
resource.

## The request-response cycle

The handling of incoming HTTP requests is done in two stages. First the request
is routed to the corresponding resource, which then handles the request by
generating a response.

HTTP requests and responses use the
[Qeweney](https://github.com/digital-fabric/qeweney) API.

## Resource types

Impression provides the following resources:

- `Resource` - a generic resource.
- `FileTree` - a resource serving static files from the given directory.
- `App` - a resource serving static files, markdown files with layouts and Ruby
  modules from the given directory.
- `RackApp` - a resource serving the given Rack app (WIP).

## Setting up a basic resource

To setup a generic resource, call `Impression.resource` and provide a request
handler:

```
app = Impression.resource { |req| req.respond('Hello, world!') }
```

## Running your app with Tipi

Impression is made for running on top of
[Tipi](https://github.com/digital-fabric/tipi). Your Tipi app file would like
something like the following:

```ruby
# app.rb
app = Impression.resource { |req| req.respond('Hello, world!') }
Tipi.run(&app)
```

You can then start Tipi by running `tipi run app.rb`.

## Running your app with a Rack app server

You can also run your app on any Rack app server, using something like the
following:

```ruby
app = Impression.resource { |req| req.respond('Hello, world!') }
run Qeweney.rack(&app)
```

## Creating a routing map with resources

A resource can be mounted at any point in the app's URL space. Resources can be
nested within other resources by passing a `parent:` argument when creating a
resource:

```ruby
app = Impression.app { |req| req.respond('Homepage') }
greeter = Impression.resource(parent: app, path: 'greeter')
static = Impression.file_tree(parent: app, path: 'static', directory: __dir__)
```


File tree resources 

## I want to know more

Further documentation is coming real soon (TM)...

## Contributing

Contributions in the form of issues, PRs or comments will be greatly
appreciated!
