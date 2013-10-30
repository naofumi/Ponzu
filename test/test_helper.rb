# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require 'minitest/pride'
require 'authlogic/test_case'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end

# Sunspot support
require 'sunspot_test'
require 'sunspot_test/test_unit'

# https://github.com/collectiveidea/sunspot_test/blob/master/lib/sunspot_test.rb
# For most of the tests, we should stub Sunspot.
# The source code shows the methods we can call to unstub and
# start the solr server.
SunspotTest.stub

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  private 

  # Read the fixture for testing mails from the Engine directory
  # This is a replacement for using #read_fixture which
  # only reads fixtures from Rails.root.
  # http://guides.rubyonrails.org/testing.html#testing-your-mailers
  def engine_read_fixture(action)
    IO.readlines(File.join(Ponzu::Engine.root, 'test', 'fixtures', self.class.mailer_class.name.underscore, action))
  end

  # Select parts of email by content_type and return
  # after decoding.
  #
  # We need this because the email.body.decoded method
  # seems to return blank on multi-part emails.
  # content_type is either "text/plain" or "text/html".
  def email_parts_of_type(email, content_type = "text/plain")
    email.body.parts.select {|part|
      if part.respond_to?(:content_type)
        part.content_type.downcase.include? content_type
      end
    }
  end

  # Assert that the first email part of content_type
  # matches content.
  def assert_email_part_of_type(email, content_type, content)
    assert_include email_parts_of_type(email, content_type).
                     map{|part| part.decoded}.first,
                   content
  end
end

class ActionController::TestCase < ActiveSupport::TestCase

  def login_as_admin
    login_as(users(:admin_1))
  end

  def login_as_user
    login_as(users(:generic_user))
  end

  def login_as(user)
    UserSession.create(user)
  end

  def mountain_lion_safari_ua
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.35+ (KHTML, like Gecko) Version/6.0.3 Safari/536.28.10"
  end

  def iphone_safari_ua
    "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
  end

  def docomo_ua
    "DoCoMo/2.0 F900i(c100;TB;W22H12)"
  end

  def ks_ajax(*args)
    @request.accept = ['text/html', 'application/json;q=0.9', 'text/javascript;q=0.8']
    xml_http_request *args
  end

  def assert_js_redirected_to(path)
    assert_response 303
    assert_equal "kss.redirect('#{path}');", @response.body
  end

  # Automatically also asserts #assert_absence_of_non_kamishibai_links.
  # To ignore some non_kamishibai_links, provide regexps to ignore:
  #
  #   assert_absence_of_non_kamishibai_links :except => [/\/assets/]
  def assert_ponzu_frame(options = {})
    ponzu_frames = css_select "[data-container='ponzu_frame']"
    if @request.user_agent != user_agent_strings_for(:galapagos)
      assert_equal 1, ponzu_frames.size, 
        "ponzu_frame not found within #{@templates.keys}"
    else
      assert_equal 0, ponzu_frames.size, 
        "ponzu_frame advertantly found within #{@templates.keys}"
    end
    assert_absence_of_non_kamishibai_links(options)
  end

  # To ignore some non_kamishibai_links, provide regexps to ignore:
  #
  #   assert_absence_of_non_kamishibai_links :except => [/\/assets/]
  def assert_absence_of_non_kamishibai_links(options = {})
    ignores = options[:except] || []
    ignores += accepted_non_kamishibai_links

    css_select("a").each do |anchor|
      href = anchor.attributes["href"]
      next if ignores.detect{|regexp| href =~ regexp}
      method = anchor.attributes["method"] || anchor.attributes["data-method"]
      next if !method.blank? && method.upcase != "GET"
      if @request.user_agent != user_agent_strings_for(:galapagos)
        if href !~ /^http/ && href !~ /^#/
          assert false, "Non-kamishibai local link for #{href} in #{@templates.keys}"
        end
      else
        if href =~ /^#!_/
          assert false, "Kamishibai local link advertantly for #{href} in #{@templates.keys}"
        end
      end
    end
  end

  def accepted_non_kamishibai_links
    [/^\/assets/, /download_pdf/, /download_full_day_pdf/, 
     /^Javascript/i, /^\/login/, /^\/logout/,
     /fukuoka_marine_messe_heimenzu/]
  end

  ### For testing multiple devices in one go
  # Test for each device by sending a request for
  # each device (as set through the UA string).
  #
  # If skip the test for a certain device, then 
  # provide the +:skip+ option.
  #
  # If you want to specifically use a certain suffix,
  # then you can set the +:suffix+ option, but I'm
  # actually sure that you don't have to do this at all.
  def scope_each_device(device_options = {})
    if device_options.empty? && defined?(self.class.device_options)
      device_options = self.class.device_options
    end
    devices_for(device_options).each do |ua_type|
      @request.user_agent = user_agent_strings_for(ua_type)

      yield ua_type
    end
  end

  # @device_options as class instance variable
  class << self
    attr_reader :device_options
  end

  # Set the default device_options for this view.
  def self.set_device_options(device_options)
    @device_options = device_options
  end

  def suffixes_for_devices
    {pc: "", smartphone: ".s", galapagos: ".g"}
  end

  # Use this to assert that the template is correct
  #
  #   def test_template
  #     scope_each_device do |type|
  #       device_selective_request [:get, :index]
  #       assert_template template_for_device(type)
  #     end
  #   end
  #
  # If you want to use a template rather then the default,
  # specify with :template => "template_name"
  #
  #    template_for_device(type, :template => "template_name")
  def template_for_device(ua_type, options = {})
    # assert_template uses String#match and hence strings are converted into
    # RegExps. We need the last '$' to discriminate 'index' from 'index.g'
    (options[:action] || @request.params[:action]).to_s + suffixes_for_devices[ua_type] + '$'
  end

  def devices_for(device_options)
    result = suffixes_for_devices.keys
    result = device_options[:only] if device_options[:only]
    if device_options[:skip]
      device_options[:skip].each do |skipped_device|
        result.delete(skipped_device)
      end
    end
    result
  end

  # Use within #scope_each_device to change the request type
  # depending on the ua_type. A :galapagos request will
  # regular HTTP, whereas other ua_types will request via Ajax.
  def device_selective_request(request_args, ua_type)
    method, action, parameters, session, flash = request_args
    unless ua_type == :galapagos
      ks_ajax method, action, parameters
    else
      process(action, parameters, session, flash, method.to_s.upcase)
    end    
  end

  def user_agent_strings_for(type)
    case type
    when :smartphone
      iphone_safari_ua
    when :galapagos
      docomo_ua
    when :pc
      mountain_lion_safari_ua
    else
      raise "No user agent string for type #{type}"
    end
  end

  alias_method :original_assert_redirected_to, :assert_redirected_to
  def assert_redirected_to(options = {}, message = nil)
    if @controller.send(:galapagos?)
      original_assert_redirected_to(options, message)
    else
      assert_response(:redirect, message)
      redirect_expected = normalize_argument_to_redirection(options).
                          sub(@request.protocol, '').sub(@request.host_with_port, "")
      expected = "#{redirect_expected}"
      if @response.body.include?("kss.redirect('#!_#{expected}');")
        return true
      else
        flunk "Expected response to be a JS redirect to <#{expected}> " +
              "but @response.body didn't contain <\"kss.redirect('#!_#{expected}');\">\n" +
              "@response.body was: " + @response.body
      end
    end
  end

end
