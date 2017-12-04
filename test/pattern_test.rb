require_relative "test_helper"

class PatternTest < Minitest::Test
  def test_tokenize
    regexp = Goodcheck::Pattern.compile_tokens("[NSData alloc]")
    assert_match regexp, "[NSData alloc]"
    assert_match regexp, "NSData *data = [[NSData alloc] init]"
    assert_match regexp, "NSData *data = [[NSData \nalloc] init]"
    refute_match regexp, "[NSData allocwithfoo]"
    refute_match regexp, "[NSDataBuffer Alloc]"
  end

  def test_tokenize2
    regexp = Goodcheck::Pattern.compile_tokens("ASCII-8BIT")
    assert_match regexp, "encode('ASCII-8BIT')"
    refute_match regexp, "FASCII-8BITS"
  end

  def test_tokenize3
    regexp = Goodcheck::Pattern.compile_tokens("<br/>")
    assert_match regexp, "Hello World<br />"
    assert_match regexp, "Hello World <br/ >"
    refute_match regexp, "Hello World <br >"
  end

  def test_literal
    pattern = Goodcheck::Pattern.literal("hello.world", case_insensitive: true)
    assert_equal /hello\.world/i, pattern.regexp
    assert_equal "hello.world", pattern.source
  end

  def test_regexp
    pattern = Goodcheck::Pattern.regexp("hello.world", case_insensitive: true, multiline: true)
    assert_equal /hello.world/im, pattern.regexp
    assert_equal "hello.world", pattern.source
  end

  def test_tokens
    pattern = Goodcheck::Pattern.token("hello.world")
    assert_equal /\bhello\s*\.\s*world\b/m, pattern.regexp
    assert_equal "hello.world", pattern.source
  end
end
