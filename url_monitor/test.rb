require File.expand_path('../../test_helper.rb', __FILE__)
require File.expand_path('../url_monitor.rb', __FILE__)

require 'open-uri'
class UrlMonitorTest < Test::Unit::TestCase
  def setup
  end

  def teardown
    FakeWeb.clean_registry
  end

  def test_initial_run_with_non_reporting_server
    uri="http://scoutapp.com"
    FakeWeb.register_uri(:head, uri, :body => "the page", :status => ["404", "Not Found"])
    @plugin=UrlMonitor.new(nil,{},{:url=>uri})
    res = @plugin.run()
    assert res[:reports].any?
    assert_equal 404, res[:reports].find { |r| r.has_key?(:status) }[:status]
    assert_equal 0, res[:reports].find { |r| r.has_key?(:up)}[:up]
    assert res[:alerts].first[:subject] =~ /is not responding/
  end

  def test_initial_run_with_reporting_server_sends_no_alert
    uri="http://scoutapp.com"
    FakeWeb.register_uri(:head, uri, :body => "the page")
    @plugin=UrlMonitor.new(nil,{},{:url=>uri})
    res = @plugin.run()
    assert res[:reports].any?
    assert_equal 1, res[:reports].find { |r| r.has_key?(:up)}[:up]
    assert_equal 0, res[:alerts].length
  end

  def test_run_with_rereporting_server
    uri="http://scoutapp.com"
    FakeWeb.register_uri(:head, uri, :body => "the page")
    @plugin=UrlMonitor.new(:last_run_stub,{},{:url=>uri})
    res = @plugin.run()
    assert res[:reports].any?
    assert_equal 1, res[:reports].find { |r| r.has_key?(:up)}[:up]
    assert res[:alerts].first[:subject] =~ /is responding/
  end

  def test_404
    uri="http://scoutapp.com"
    FakeWeb.register_uri(:head, uri, :body => "the page", :status => ["404", "Not Found"])
    @plugin=UrlMonitor.new(nil,{},{:url=>uri})
    res = @plugin.run()
    assert res[:reports].any?
    assert_equal 404, res[:reports].find { |r| r.has_key?(:status) }[:status]
    assert_equal 0, res[:reports].find { |r| r.has_key?(:up)}[:up]
    assert res[:alerts].first[:subject] =~ /is not responding/
  end

  def test_bad_host
    uri = "http://fake"
    @plugin = UrlMonitor.new(nil,{},{:url=>uri})
    res = @plugin.run()
    assert_equal 0, res[:reports].find { |r| r.has_key?(:up)}[:up]
    assert res[:alerts].first[:subject] =~ /is not responding/
  end

  def test_sends_head_request
    uri = "http://scoutapp.com"
    FakeWeb.register_uri(:head, uri, :body => "the page")
    @plugin = UrlMonitor.new(nil,{},{:url=>uri})
    res = @plugin.run()
    assert_equal "HEAD", FakeWeb.last_request.method
  end

  def test_sends_get_request
    uri = "http://scoutapp.com"
    FakeWeb.register_uri(:get, uri, :body => "the page")
    @plugin = UrlMonitor.new(nil, {}, {:url => uri, :request_method => 'GET'})
    res = @plugin.run()
    assert_equal "GET", FakeWeb.last_request.method
  end

  def test_sends_post_request
    uri = "http://scoutapp.com"
    request_body_content = "{ 'foo':'bar' }"
    FakeWeb.register_uri(:post, uri, :body => "the page", :parameters => {:foo => 'bar'}, :status => ["200" => "OK"])
    @plugin = UrlMonitor.new(nil, {}, {:url => uri, :request_method => 'POST', :request_body_content => request_body_content})
    res = @plugin.run()
    assert_equal "POST", FakeWeb.last_request.method
  end
end
