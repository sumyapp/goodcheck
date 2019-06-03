$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "goodcheck"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "test_case_builder"
require "open3"
require "securerandom"
require "tmpdir"

module Assertions
  def assert_pattern(object, regexp: nil, source: nil)
    assert_instance_of Goodcheck::Pattern, object
    assert_equal regexp, object.regexp if regexp
    assert_equal source, object.source if source
  end
end

module Outputs
  def stderr
    @stderr ||= StringIO.new
  end

  def stdout
    @stdout ||= StringIO.new
  end
end

Rainbow.enabled = false

module TestHelper
  def mktmpdir
    Dir.mktmpdir do |dir|
      yield Pathname(dir)
    end
  end
end
