# frozen_string_literal: true

require_relative 'helper'
require 'qeweney/test_adapter'

class JamstackTest < MiniTest::Test
  JAMSTACK_PATH = File.join(__dir__, 'jamstack')

  def setup
    @jamstack = Impression::Jamstack.new(path: '/', directory: JAMSTACK_PATH)
  end

  def test_jamstack_routing
    req = mock_req(':method' => 'GET', ':path' => '/')
    assert_equal @jamstack, @jamstack.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/nonexistent')
    assert_equal @jamstack, @jamstack.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/index.html')
    assert_equal @jamstack, @jamstack.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    assert_equal @jamstack, @jamstack.route(req)
  end

  def static(path)
    IO.read(File.join(JAMSTACK_PATH, path))
  end

  def test_jamstack_response
    req = mock_req(':method' => 'GET', ':path' => '/roo')
    @jamstack.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/foo2')
    @jamstack.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/bar2')
    @jamstack.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/assets/js/a.js')
    @jamstack.route_and_call(req)
    assert_response static('assets/js/a.js'), :js, req

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    @jamstack.route_and_call(req)

    foo = H {
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
    @jamstack.route_and_call(req)

    index = H {
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
    @jamstack.route_and_call(req)
    assert_response index.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/bar')
    @jamstack.route_and_call(req)
    assert_response static('bar.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/baz')
    @jamstack.route_and_call(req)

    baz_index = H {
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
    @jamstack.route_and_call(req)

    a = H {
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

  def test_non_root_jamstack_response
    @jamstack = Impression::Jamstack.new(path: '/app', directory: JAMSTACK_PATH)

    req = mock_req(':method' => 'GET', ':path' => '/app/roo')
    @jamstack.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/foo2')
    @jamstack.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/bar2')
    @jamstack.route_and_call(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/assets/js/a.js')
    @jamstack.route_and_call(req)
    assert_response static('assets/js/a.js'), :js, req

    req = mock_req(':method' => 'GET', ':path' => '/app/foo')
    @jamstack.route_and_call(req)

    foo = H {
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
    @jamstack.route_and_call(req)

    index = H {
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
    @jamstack.route_and_call(req)
    assert_response index.render, :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/bar')
    @jamstack.route_and_call(req)
    assert_response static('bar.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/baz')
    @jamstack.route_and_call(req)

    baz_index = H {
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
    @jamstack.route_and_call(req)

    a = H {
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
    @jamstack = Impression::Jamstack.new(path: '/app', directory: JAMSTACK_PATH)

    list = @jamstack.page_list('/')
    assert_equal [
      { kind: :file, path: File.join(JAMSTACK_PATH, 'bar.html'), ext: '.html', url: '/app/bar' },
      { kind: :file, path: File.join(JAMSTACK_PATH, 'index.md'), ext: '.md', url: '/app', 
        title: 'Hello', foo: 'BarBar', markdown_content: '<h1>Index</h1>' },
    ], list


    list = @jamstack.page_list('/articles')

    assert_equal [
      {
        kind: :file,
        path: File.join(JAMSTACK_PATH, 'articles/2008-06-14-manu.md'),
        url: '/app/articles/2008-06-14-manu',
        ext: '.md',
        title: 'MMM',
        layout: 'article',
        markdown_content: "## BBB\n",
        date: Date.new(2008, 06, 14)
      },
      {
        kind: :file,
        path: File.join(JAMSTACK_PATH, 'articles/2009-06-12-noatche.md'),
        url: '/app/articles/2009-06-12-noatche',
        ext: '.md',
        title: 'NNN',
        layout: 'article',
        markdown_content: "## CCC\n",
        date: Date.new(2009, 06, 12)
      },
      { 
        kind: :file,
        path: File.join(JAMSTACK_PATH, 'articles/a.md'),
        url: '/app/articles/a',
        ext: '.md',
        title: 'AAA',
        layout: 'article',
        markdown_content: "## ZZZ\n"
      },
    ], list
  end

  def test_template_resource_and_request
    req = mock_req(':method' => 'GET', ':path' => '/foobar?q=42')
    @jamstack.route_and_call(req)
  
    foo = H {
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
    @jamstack.send(:get_path_info, path)
  end

  def test_path_info
    assert_equal({
      kind: :file,
      path: File.join(JAMSTACK_PATH, 'index.md'),
      ext: '.md',
      url:  '/',
      title: 'Hello',
      foo: 'BarBar',
      markdown_content: '<h1>Index</h1>'
    },  path_info('/index'))

    assert_equal({
      kind: :file,
      path: File.join(JAMSTACK_PATH, 'index.md'),
      ext: '.md',
      url:  '/',
      title: 'Hello',
      foo: 'BarBar',
      markdown_content: '<h1>Index</h1>'
    },  path_info('/'))

    assert_equal({
      kind: :file,
      path: File.join(JAMSTACK_PATH, 'assets/js/a.js'),
      ext: '.js',
      url:  '/assets/js/a.js'
    },  path_info('/assets/js/a.js'))

    assert_equal({
      kind: :not_found,
    },  path_info('/js/b.js'))
  end
end
