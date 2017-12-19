# Goodcheck - Regexp based customizable linter

Tired to run `grep` on your source code?
Try Goodcheck!

## Installation

```bash
$ gem install goodcheck
```

Or you can use `bundler`!

## Usage

### Setup

```bash
$ goodcheck init
```

The `init` command generate template of `goodcheck.yml` configuration file for you.
Edit the config file to define patterns you want to check.

### goodcheck.yml

Define the patterns you want to check in your source code.

```yaml
rules:
  - id: com.example.no_br
    pattern: <br />
    suffixes:
      - .html.erb
      - .html
    message: |
      Try not using <br /> to format text in HTML
      
      Using line breaks, <br />, is not recommended.
      Use <p> or <div> tags to define paragraphs, and let user agent to break lines.
    assert:
      - <div>Text here.<br />Another text here.</div>
    refute:
      - |
        <div>Text here.</div>
        <div>Another text here.</div>
  - id: com.example.no_nsdate_formatter_alloc
    pattern:
      regexp: "\bCALL_API\b"
    suffixes:
      - .js
      - .ts
      - .coffee
    message: |
      CALL_API should not be used
      
      CALL_API is too generic name and insufficient descriptive.
      Try using more specific name.
    assert:
      - CALL_API
      - "{ [CALL_API]: function() { ... } }"
    refute:
      - CALL_INDEX_API
  - id: com.example.no_function
    pattern:
      token: function(
    suffixes:
      - .js
      - .ts
    message: |
      We are in ES6 world!
      
      Use arrow function syntax `=>` instead of `function`
    assert:
      - "function () { console.log('hello world') }"
      - "function(data) { ... }"
    refute:
      - "=> { console.log('hello world') }"
      - "(data) => { ... }"
  - id: com.example.no_redundant_parens
    pattern:
      token: ()=>
    suffixes:
      - .js
      - .ts
    message: |
      
```

## Patterns

Goodcheck allows to write three kind of patterns.

* `regexp` pattern, compiles to a regexp of Ruby
* `literal` pattern, compiles to a regexp which corresponds to the input literal
* `token` pattern, compiles to a special *tokenizing* regexp

### Token pattern

*Token pattern* allows to define a regexp which is almost tokenized to wide range of programming languages.

* `function()` compiles to `/\bfunction\s*\(\s*\)/`
* `[NSDateFormatter alloc]` compiles to `/\[\s*NSDateFormatter\s+alloc\s*\]/`

The translation is defined as the below:

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sideci/goodcheck.
