require_relative "test_helper"

class ConfigLoaderTest < Minitest::Test
  include Assertions

  ConfigLoader = Goodcheck::ConfigLoader
  Rule = Goodcheck::Rule

  def test_load_pattern_string
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "")
    pattern = loader.load_pattern "foo.bar"

    assert_pattern pattern, regexp: /foo\.bar/, source: "foo.bar"
  end

  def test_load_literal_pattern_hash_ci
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "")
    pattern = loader.load_pattern({ literal: "foo.bar", case_insensitive: true })

    assert_pattern pattern, regexp: /foo\.bar/i, source: "foo.bar"
  end

  def test_load_literal_pattern_hash_cs
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "")
    pattern = loader.load_pattern({ literal: "foo.bar", case_insensitive: false })

    assert_pattern pattern, regexp: /foo\.bar/, source: "foo.bar"
  end

  def test_load_regexp_pattern
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "")
    pattern = loader.load_pattern({ regexp: "foo.bar" })

    assert_pattern pattern, regexp: /foo.bar/, source: "foo.bar"
  end

  def test_load_regexp_pattern_ci_multi
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "")
    pattern = loader.load_pattern({ regexp: "foo.bar", case_insensitive: true, multiline: true })

    assert_pattern pattern, regexp: /foo.bar/im, source: "foo.bar"
  end

  def test_load_token_pattern
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "")
    pattern = loader.load_pattern({ token: "foo.bar" })

    assert_pattern pattern, regexp: /\bfoo\s*\.\s*bar\b/m, source: "foo.bar"
  end

  def test_load_globs
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "")

    g1, g2, g3, _ = loader.load_globs(["foo", { pattern: "foo/bar" }, { pattern: "*.rb", encoding: "Shift_JIS" }])

    assert_equal "foo", g1.pattern
    assert_nil g1.encoding

    assert_equal "foo/bar", g2.pattern
    assert_nil g2.encoding

    assert_equal "*.rb", g3.pattern
    assert_equal "Shift_JIS", g3.encoding
  end

  def test_load_rule
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "")
    rule = loader.load_rule({ id: "com.id.1", message: "Some message", pattern: "foo.bar" })

    assert_instance_of Rule, rule
    assert_equal "com.id.1", rule.id
    assert_equal "Some message", rule.message
    assert_equal ["foo.bar"], rule.patterns.map(&:source)
    assert_equal [], rule.justifications
    assert_equal [], rule.globs
    assert_equal [], rule.passes
    assert_equal [], rule.fails
  end

  def test_load_config_failure
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: [{}])
    assert_raises StrongJSON::Type::Error do
      loader.load
    end
  end

  def test_load_encoding_failure
    loader = ConfigLoader.new(path: Pathname("hello.yml"),
                              content: {
                                rules: [
                                  {
                                    id: "foo",
                                    pattern: "bar",
                                    message: "baz",
                                    glob: { pattern: "*.rb", encoding: "UNKNOWN_ENCODING😍"}
                                  }
                                ]
                              })

    exn = nil
    begin
      loader.load
    rescue => exn
    end

    assert_equal [:rules, 0, :glob], exn.path
  end

  def test_load_config
    loader = ConfigLoader.new(path: Pathname("hello.yml"),
                              content: {
                                rules: [
                                  {
                                    id: "foo",
                                    pattern: "string",
                                    message: "Hello",
                                  },
                                  {
                                    id: "bar",
                                    pattern: "string",
                                    message: "Hello",
                                    justification: ["Some reason"],
                                    glob: [
                                      "**/*.rb",
                                      { pattern: "**/Rakefile", encoding: "EUC-JP" },
                                      { pattern: "*.gemspec" }
                                    ],
                                    pass: ["hoge"],
                                    fail: ["huga"]
                                  },
                                  {
                                    id: "baz",
                                    pattern:
                                      [
                                        { regexp: "hoge" },
                                        { literal: "foo" },
                                        { token: "bar" }
                                      ],
                                    message: "Hello World",
                                    justification: "a reason",
                                    glob: "foo",
                                    pass: "hoge",
                                    fail: "baz"
                                  }
                                ]
                              })

    loader.load
  end
end
