require_relative "test_helper"

class CheckCommandTest < Minitest::Test
  include Outputs

  Check = Goodcheck::Commands::Check
  Reporters = Goodcheck::Reporters

  def test_check
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      - foo
      - bar
    glob: 
      - "app/models/**/*.rb"
EOF

      builder.file name: Pathname("app/models/user.rb"), content: <<EOF
class User < ApplicationRecord
  belongs_to :foo
end
EOF

      builder.file name: Pathname("app/views/welcome/index.html.erb"), content: <<EOF
<h1>Foo Bar Baz</h1>
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout, stderr: stderr)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter)

        assert_equal 0, check.run

        refute_match %r(app/models/user\.rb:1:class User < ApplicationRecord), stdout.string
        assert_match %r(app/models/user\.rb:2:  belongs_to :foo:\tFoo), stdout.string
        refute_match %r(app/views/welcome/index\.html\.erb), stdout.string
      end
    end
  end

  def test_broken_yaml_error
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
      pattern:
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout, stderr: stderr)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter)

        assert_equal 1, check.run

        assert_match /Unexpected error happens while loading YAML file: #<Psych::SyntaxError:/, stderr.string
      end
    end
  end

  def test_invalid_config
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout, stderr: stderr)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter)

        assert_equal 1, check.run

        assert_match /Invalid config at \[rules\]\[0\]\[pattern\]/, stderr.string
      end
    end
  end

  def test_encoding
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern: 猫
    glob: 
      - pattern: euc-jp
        encoding: EUC-JP
      - pattern: utf-8
EOF

      builder.file name: Pathname("euc-jp"), content: <<EOF.encode("EUC-JP")
吾輩は猫である。
EOF

      builder.file name: Pathname("utf-8"), content: <<EOF
吾輩は猫である。
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout, stderr: stderr)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter)

        assert_equal 0, check.run

        assert_match %r(euc-jp:1:吾輩は猫である。), stdout.string
        assert_match %r(utf-8:1:吾輩は猫である。), stdout.string
      end
    end
  end

  def test_no_config
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout, stderr: stderr)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter)

        assert_equal 1, check.run

        assert_match /No such file or directory @ rb_sysopen/, stderr.string
      end
    end
  end
end
