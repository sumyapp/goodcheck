![Goodcheck logo](logo/GoodCheck%20Horizontal.png)

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

If you would not like to install Goodcheck to system (e.g. you would not like to install Ruby 2.4 or higher), you can use a docker image. [See below](#docker-images).

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
    justification:
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
When a string is given, it is interpreted as a *literal pattern* with `case_sensitive: true`.

#### *literal pattern*

*literal pattern* allows you to construct a regexp which matches exactly to the `literal` string.

```yaml
id: com.sample.GitHub
pattern:
  literal: Github
  case_sensitive: true
  glob: []
message: Write GitHub, not Github
```

All regexp meta characters included in the `literal` value will be escaped.
`case_sensitive` is an optional key and the default is `true`.
`glob` is an optional key and the default is empty.

#### *regexp pattern*

*regexp pattern* allows you to write a regexp with meta chars.

```yaml
id: com.sample.digits
pattern:
  regexp: \d{4,}
  case_sensitive: false
  multiline: false
  glob: []
message: Insert delimiters when writing large numbers
justification:
  - When you are not writing numbers, including phone numbers, zip code, ...
```

It accepts two optional attributes, `case_sensitive`, `multiline`, and `glob`.
The default values of `case_sensitive` and `multiline` are `true` and `false` respectively.

The regexp will be passed to `Regexp.compile`.
The precise definition of regular expression can be found in the documentation for Ruby.

#### *token pattern*

*token pattern* compiles to a *tokenized* regexp.

```yaml
id: com.sample.no-blink
pattern:
  token: "<blink"
  case_sensitive: false
  glob: []
message: Stop using <blink> tag
glob: "**/*.html"
justification:
  - If Lynx is the major target of the web site
```

It tries to tokenize the input and generates a regexp which matches sequence of tokens.
The tokenization is heuristic and may not work well for your programming language.
In that case, try using *regexp pattern*.

The generated regexp of `<blink` is `<\s*blink\b/m`.
It matches with `<blink />` and `< BLINK>`, but does not match with `https://www.chromium.org/blink`.

It accepts one optional attributes, `case_sensitive` and `glob`.
The default value of `case_sensitive` is `true`.
Note that the generated regexp is in multiline mode.

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

If both of your rule and its pattern has `glob`, Goodcheck will scan the pattern from the `glob` files in the pattern.

```yaml
rules:
  - id: glob_test
    pattern:
      - literal: 123      # This pattern applies to .css files
        glob: "*.css"
      - literal: abc      # This pattern applies to .txt files
    glob: "*.txt"
```

## Importing rules

`goodcheck.yml` can have optional `import` attribute.

```yaml
rules: []
import:
  - /usr/share/goodcheck/rules.yml
  - lib/goodcheck/rules.yml
  - https://some.host/shared/rules.yml
```

Value of `import` can be an array of:

- A string which represents an absolute file path,
- A string which represents an relative file path from config file, or
- A http/https URL which represents the location of rules

The rules file is a YAML file with array of rules.

## Excluding files

`goodcheck.yml` can have optional `exclude` attribute.

```yaml
rules: []
exclude:
  - node_modules
  - vendor
```

Value of `exclude` can be a string or an array of strings representing the glob pattern for excluded files.

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
* `-v`, `--verbose` to be verbose.
* `--debug` to print all debug messages.
* `--force` to ignore downloaded caches

`goodcheck check` exits with:

* `0` when it does not find any matching text fragment
* `2` when it finds some matching text
* `1` when it finds some error

You can check its exit status to identify if the tool find some pattern or not.

### `goodcheck test [options]`

The `test` command tests rules.
The test contains:

* Validation of rule `id` uniqueness.
* If `pass` examples does not match with any of `pattern`s.
* If `fail` examples matches with some of `pattern`s.

Use `test` command when you add new rule to be sure you are writing rules correctly.

Available options is:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file.
* `-v`, `--verbose` to be verbose.
* `--debug` to print all debug messages.
* `--force` to ignore downloaded caches

## Downloaded rules

Downloaded rules are cached in `cache` directory in *goodcheck home directory*.
The *goodcheck home directory* is `~/.goodcheck`, but you can customize the location with `GOODCHECK_HOME` environment variable.

The cache expires in 3 minutes.

## Docker Images

You can use [Docker images](https://hub.docker.com/r/sider/goodcheck/) to use Goodcheck.
For example:

```bash
$ docker pull sider/goodcheck

$ cd /path/to/your/project
$ docker run -it --rm -v "$(pwd):/work" sider/goodcheck goodcheck check
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/sider/goodcheck).
