# Goodcheck - Regexp based customizable linter

Are you reviewing a pull request if the change contains deprecated API calls?
Do you want to post a comment to ask the developer if a method call satisfies some condition to use that without causing an issue?
What if a misspelling like `Github` for `GitHub` can be found automatically?

Give Goodcheck a try to do them instead of you! 🎉

Goodcheck is a customizable linter.
You can define pairs of patterns and messages.
It checks your program and when it detects a piece of text matching with the defined patterns, it prints your message which tells your teammates why it should be revised and how.
Some part of code reviewing process can be automated.
Everything you have to do is to define the rules, pairs of patterns and messages, and nothing will bother you. 😆

## Installation

```bash
$ gem install goodcheck
```

Or you can use `bundler`!

If you would not like to install Goodcheck to system (e.g. you would not like to install Ruby 2.4 or higher), you can use a docker image. [See below](#docker-image).

## Quickstart

```bash
$ goodcheck init
$ vim goodcheck.yml
$ goodcheck check
```

The `init` command generates template of `goodcheck.yml` configuration file for you.
Edit the config file to define patterns you want to check.
Then run `check` command, and it will print matched texts.

## `goodcheck.yml`

An example of configuration is like the following:

```yaml
rules:
  - id: com.example.github
    pattern: Github
    message: |
      GitHub is GitHub, not Github

      You may misspelling the name of the service!
    justifications:
      - When you mean a service different from GitHub
      - When GitHub is renamed
    glob:
      - app/views/**/*.html.slim
      - config/locales/**/*.yaml
    pass:
      - <a>Signup via GitHub</a>
    fail:
      - <a>Signup via Github</a>
```

The *rule* hash contains the following keys.

* `id`: a string to identify rules (required)
* `pattern`: a *pattern* or a sequence of *pattern*s (required)
* `message`: a string to tell writers why the code piece should be revised (required)
* `justification`: a sequence of strings to tell writers when a exception can be allowed (optional)
* `glob`: a *glob* or a sequence of *glob*s (optional)
* `pass`: a string, or a sequence of strings, which does not match given pattern (optional)
* `fail`: a string, or a sequence of strings, which does match given pattern (optional)

### *pattern*

A *pattern* can be a *literal pattern*, *regexp pattern*, *token pattern*, or a string.
When a string is given, it is interpreted as a *literal pattern* with `case_insensitive: false`.

#### *literal pattern*

*literal pattern* allows you to construct a regexp which matches exactly to the `literal` string.

```yaml
id: com.sample.GitHub
pattern:
  literal: Github
  case_insensitive: false
message: Write GitHub, not Github
```

All regexp meta characters included in the `literal` value will be escaped.
`case_insensitive` is an optional key and the default is `false`.

#### *regexp pattern*

*regexp pattern* allows you to write a regexp with meta chars.

```yaml
id: com.sample.digits
pattern:
  regexp: \d{4,}
  case_insensitive: true
  multiline: false
message: Insert delimiters when writing large numbers
justification:
  - When you are not writing numbers, including phone numbers, zip code, ...
```

It accepts two optional attributes, `case_insensitive` and `multiline`.
The default values of `case_insensitive` and `multiline` are `false`.

The regexp will be passed to `Regexp.compile`.
The precise definition of regular expression can be found in the documentation for Ruby.

#### *token pattern*

*token pattern* compiles to a *tokenized* regexp.

```yaml
id: com.sample.no-blink
pattern:
  token: "<blink"
  case_insensitive: true
message: Stop using <blink> tag
glob: "**/*.html"
justifications:
  - If Lynx is the major target of the web site
```

It tries to tokenize the input and generates a regexp which matches sequence of tokens.
The tokenization is heuristic and may not work well for your programming language.
In that case, try using *regexp pattern*.

The generated regexp of `<blink` is `<\s*blink\b`.
It matches with `<blink />` and `< BLINK>`, but does not match with `https://www.chromium.org/blink`.

It accepts one optional attribute, `case_insensitive`.
The default value of `case_insensitive` is `false`.

### *glob*

A *glob* can be a string, or a hash.

```yaml
glob:
  pattern: "legacy/**/*.rb"
  encoding: EUC-JP
```

The hash can have an optional `encoding` attribute.
You can specify encoding of the file by the names defined for ruby.
The list of all available encoding names can be found by `$ ruby -e "puts Encoding.name_list"`.
The default value is `UTF-8`.

If you write a string as a `glob`, the string value can be the `pattern` of the glob, without `encoding` attribute.

If you omit `glob` attribute in a rule, the rule will be applied to all files given to `goodcheck`.

## Commands

### `goodcheck init [options]`

The `init` command generates an example of configuration file.

Available options are:

* `-c=[CONFIG]`, `--config=[CONFIG]` to specify the configuration file name to generate.
* `--force` to allow overwriting existing config file.

### `goodcheck check [options] targets...`

The `check` command checks your programs under `targets...`.
You can pass:

* Directory paths, or
* Paths to files.

When you omit `targets`, it checks all files in `.`.

Available options are:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file.
* `-R [rule]`, `--rule=[rule]` to specify the rules you want to check.
* `--format=[text|json]` to specify output format.

### `goodcheck test [options]`

The `test` command tests rules.
The test contains:

* Validation of rule `id` uniqueness.
* If `pass` examples does not match with any of `pattern`s.
* If `fail` examples matches with some of `pattern`s.

Use `test` command when you add new rule to be sure you are writing rules correctly.

Available options is:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file.

## Docker image

You can use a docker image to use Goodcheck.

```bash
$ git clone https://github.com/sideci/goodcheck
$ cd goodcheck
$ docker build -t goodcheck:latest .

$ cd /path/to/your/project
$ docker run -it --rm -v "$(pwd):/work" goodcheck:latest goodcheck check
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sideci/goodcheck.
