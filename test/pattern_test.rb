require_relative "test_helper"

class PatternTest < Minitest::Test
  def test_tokenize
    regexp = Goodcheck::Pattern.compile_tokens("[NSData alloc]", case_insensitive: false)
    assert_match regexp, "[NSData alloc]"
    assert_match regexp, "NSData *data = [[NSData alloc] init]"
    assert_match regexp, "NSData *data = [[NSData \nalloc] init]"
    refute_match regexp, "[NSData allocwithfoo]"
    refute_match regexp, "[NSDataBuffer Alloc]"
  end

  def test_tokenize2
    regexp = Goodcheck::Pattern.compile_tokens("ASCII-8BIT", case_insensitive: false)
    assert_match regexp, "encode('ASCII-8BIT')"
    refute_match regexp, "FASCII-8BITS"
  end

  def test_tokenize3
    regexp = Goodcheck::Pattern.compile_tokens("<br/>", case_insensitive: false)
    assert_match regexp, "Hello World<br />"
    assert_match regexp, "Hello World <br/ >"
    refute_match regexp, "Hello World <br >"
  end

  def test_tokenize4
    regexp = Goodcheck::Pattern.compile_tokens("沖縄Ruby会議", case_insensitive: false)
    assert_match regexp, "沖縄Ruby会議"
    assert_match regexp, "沖縄 Ruby 会議"
    refute_match regexp, "沖 縄Ruby会議"
  end

  def test_tokenize5
    regexp = Goodcheck::Pattern.compile_tokens("each", case_insensitive: false)
    assert_match regexp, "each()"
    assert_match regexp, "foo.each()"
    refute_match regexp, "foreach"
    refute_match regexp, "test_each_icon"
  end

  def test_tokenize6
    regexp = Goodcheck::Pattern.compile_tokens("each", case_insensitive: true)
    assert_match regexp, "EACH()"
    assert_match regexp, "foo.Each()"
    refute_match regexp, "FOReaCH"
    refute_match regexp, "test_each_icon"
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
    pattern = Goodcheck::Pattern.token("hello.world", case_insensitive: false)
    assert_equal /\bhello\s*\.\s*world\b/m, pattern.regexp
    assert_equal "hello.world", pattern.source
  end
end
