# frozen_string_literal: true

require_relative 'helper'
require 'qeweney/test_adapter'

class AppTest < MiniTest::Test
  APP_PATH = File.join(__dir__, 'app')

  def setup
    @app = Impression::App.new(path: '/', directory: APP_PATH)
  end

  def test_app_routing
    req = mock_req(':method' => 'GET', ':path' => '/')
    assert_equal @app, @app.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/nonexistent')
    assert_equal @app, @app.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/index.html')
    assert_equal @app, @app.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    assert_equal @app, @app.route(req)
  end

  def static(path)
    IO.read(File.join(APP_PATH, path))
  end

  def test_app_response
    req = mock_req(':method' => 'GET', ':path' => '/roo')
    @app.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/foo2')
    @app.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/bar2')
    @app.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/assets/js/a.js')
    @app.route_and_call(req)
    assert_response static('assets/js/a.js'), :js, req

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    @app.route_and_call(req)

    foo = Papercraft.html {
      html5 {
        head {
          title 'Foo title'
        }
        body {
          h1 'foo'
        }
      }
    }
    assert_response foo.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/index')
    @app.route_and_call(req)

    index = Papercraft.html {
      html5 {
        head {
          title 'Hello'
        }
        body {
          h1 'Index'
        }
      }
    }
    assert_response index.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/')
    @app.route_and_call(req)
    assert_response index.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/bar')
    @app.route_and_call(req)
    assert_response static('bar.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/baz')
    @app.route_and_call(req)

    baz_index = Papercraft.html {
      html5 {
        head {
          title 'BarBar'
        }
        body {
          h1 'BarIndex'
        }
      }
    }
    assert_response baz_index.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/articles/a')
    @app.route_and_call(req)

    a = Papercraft.html {
      html5 {
        head {
          title 'AAA'
        }
        body {
          article {
            h2 'ZZZ', id: 'zzz'
          }
        }
      }
    }
    assert_response a.render, :html, req
  end

  def test_non_root_app_response
    @app = Impression::App.new(path: '/app', directory: APP_PATH)

    req = mock_req(':method' => 'GET', ':path' => '/app/roo')
    @app.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/foo2')
    @app.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/bar2')
    @app.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/assets/js/a.js')
    @app.route_and_call(req)
    assert_response static('assets/js/a.js'), :js, req

    req = mock_req(':method' => 'GET', ':path' => '/app/foo')
    @app.route_and_call(req)

    foo = Papercraft.html {
      html5 {
        head {
          title 'Foo title'
        }
        body {
          h1 'foo'
        }
      }
    }
    assert_response foo.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/index')
    @app.route_and_call(req)

    index = Papercraft.html {
      html5 {
        head {
          title 'Hello'
        }
        body {
          h1 'Index'
        }
      }
    }
    assert_response index.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/')
    @app.route_and_call(req)
    assert_response index.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/bar')
    @app.route_and_call(req)
    assert_response static('bar.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/baz')
    @app.route_and_call(req)

    baz_index = Papercraft.html {
      html5 {
        head {
          title 'BarBar'
        }
        body {
          h1 'BarIndex'
        }
      }
    }
    assert_response baz_index.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/articles/a')
    @app.route_and_call(req)

    a = Papercraft.html {
      html5 {
        head {
          title 'AAA'
        }
        body {
          article {
            h2 'ZZZ', id: 'zzz'
          }
        }
      }
    }
    assert_response a.render, :html, req
  end

  def test_page_list
    @app = Impression::App.new(path: '/app', directory: APP_PATH)

    list = @app.page_list('/')
    assert_equal [
      { kind: :file, path: File.join(APP_PATH, 'bar.html'), ext: '.html', url: '/app/bar' },
      { kind: :markdown, path: File.join(APP_PATH, 'index.md'), ext: '.md', url: '/app', 
        title: 'Hello', foo: 'BarBar', html_content: "<h1>Index</h1>\n" },
    ], list


    list = @app.page_list('/articles')

    assert_equal [
      {
        kind: :markdown,
        path: File.join(APP_PATH, 'articles/2008-06-14-manu.md'),
        url: '/app/articles/2008-06-14-manu',
        ext: '.md',
        title: 'MMM',
        layout: 'article',
        foo: {
          bar: {
            baz: 42
          }
        },
        html_content: "<h2 id=\"bbb\">BBB</h2>\n",
        date: Date.new(2008, 06, 14)
      },
      {
        kind: :markdown,
        path: File.join(APP_PATH, 'articles/2009-06-12-noatche.md'),
        url: '/app/articles/2009-06-12-noatche',
        ext: '.md',
        title: 'NNN',
        layout: 'article',
        html_content: "<h2 id=\"ccc\">CCC</h2>\n",
        date: Date.new(2009, 06, 12)
      },
      { 
        kind: :markdown,
        path: File.join(APP_PATH, 'articles/a.md'),
        url: '/app/articles/a',
        ext: '.md',
        title: 'AAA',
        layout: 'article',
        html_content: "<h2 id=\"zzz\">ZZZ</h2>\n",
      },
    ], list
  end

  def test_template_resource_and_request
    req = mock_req(':method' => 'GET', ':path' => '/foobar?q=42')
    @app.route_and_call(req)
  
    foo = Papercraft.html {
      html5 {
        head {
          title 'Foobar'
        }
        body {
          h1 '42'
          a 'MMM', href: '/articles/2008-06-14-manu'
          a 'NNN', href: '/articles/2009-06-12-noatche'
          a 'AAA', href: '/articles/a'
        }
      }
    }
    assert_response foo.render, :html, req
  end

  def path_info(path)
    @app.send(:get_path_info, path)
  end

  def test_path_info
    assert_equal({
      kind: :markdown,
      path: File.join(APP_PATH, 'index.md'),
      ext: '.md',
      url:  '/',
      title: 'Hello',
      foo: 'BarBar',
      html_content: "<h1>Index</h1>\n"
    },  path_info('/index'))

    assert_equal({
      kind: :markdown,
      path: File.join(APP_PATH, 'index.md'),
      ext: '.md',
      url:  '/',
      title: 'Hello',
      foo: 'BarBar',
      html_content: "<h1>Index</h1>\n"
    },  path_info('/'))

    assert_equal({
      kind: :file,
      path: File.join(APP_PATH, 'assets/js/a.js'),
      ext: '.js',
      url:  '/assets/js/a.js'
    },  path_info('/assets/js/a.js'))

    assert_equal({
      kind: :not_found,
    },  path_info('/js/b.js'))
  end

  def test_resource_loading
    req = mock_req(':method' => 'GET', ':path' => '/resources/greeter?name=world')
    route = @app.route(req)
    assert_equal @app, route

    req = mock_req(':method' => 'GET', ':path' => '/resources/greeter?name=world')
    @app.route_and_call(req)
    assert_response 'Hello, world!', :text, req

    req = mock_req(':method' => 'GET', ':path' => '/resources/recurse/resources/greeter?name=foo')
    @app.route_and_call(req)
    assert_response 'Hello, foo!', :text, req
  end

  def test_recursive_resource_loading_on_non_root_app
    app = Impression::App.new(path: '/foo/bar', directory: APP_PATH)

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar/resources/greeter?name=world')
    route = app.route(req)
    assert_equal app, route

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar/resources/greeter?name=world')
    app.route_and_call(req)
    assert_response 'Hello, world!', :text, req

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar/resources/recurse/resources/greeter?name=foo')
    app.route_and_call(req)
    assert_response 'Hello, foo!', :text, req

    # req = mock_req(':method' => 'GET', ':path' => '/foo/bar/resources/recurse/bar')
    # @app.route_and_call(req)
    # assert_response static('bar.html'), :html, req
  end
end

class AbstractAppTest < MiniTest::Test
  def test_abstract_app_default_response
    app = Impression::App.new(path: '/')
    req = mock_req(':method' => 'GET', ':path' => '/')

    app.call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status
  end

  def test_abstract_app_each
    app = Impression::App.new(path: '/')
    
    buffer = []
    app.each { |r| buffer << r }
    assert_equal [app], buffer

    foo = PathRenderingResource.new(parent: app, path: 'foo')
    bar = PathRenderingResource.new(parent: app, path: 'bar')
    
    buffer = []
    app.each { |r| buffer << r }
    assert_equal [app, foo, bar], buffer
  end

  def test_app_to_proc
    app = Impression::App.new(path: '/')
    app_proc = app.to_proc

    foo = PathRenderingResource.new(parent: app, path: 'foo')
    bar = PathRenderingResource.new(parent: app, path: 'bar')

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    app_proc.(req)
    assert_equal '/foo', req.adapter.body

    req = mock_req(':method' => 'GET', ':path' => '/bar')
    app_proc.(req)
    assert_equal '/bar', req.adapter.body

    req = mock_req(':method' => 'GET', ':path' => '/baz')
    app_proc.(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status
  end
end
