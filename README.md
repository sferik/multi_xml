# MultiXML

[![Tests](https://github.com/sferik/multi_xml/actions/workflows/tests.yml/badge.svg)][tests]
[![Linter](https://github.com/sferik/multi_xml/actions/workflows/linter.yml/badge.svg)][linter]
[![Mutant](https://github.com/sferik/multi_xml/actions/workflows/mutant.yml/badge.svg)][mutant]
[![Typecheck](https://github.com/sferik/multi_xml/actions/workflows/typecheck.yml/badge.svg)][typecheck]
[![Docs](https://github.com/sferik/multi_xml/actions/workflows/docs.yml/badge.svg)][docs]
[![Gem Version](https://badge.fury.io/rb/multi_xml.svg)][gem]

Lots of Ruby libraries parse XML and everyone has their favorite XML parser.
Instead of choosing a single XML parser and forcing users of your library to
be stuck with it, you can use MultiXML instead, which will simply choose the
fastest available XML parser. Here's how to use it:

```ruby
require "multi_xml"

MultiXML.parse("<tag>contents</tag>")                        #=> {"tag" => "contents"}
MultiXML.parse("<tag>contents</tag>", symbolize_keys: true)  #=> {tag: "contents"}
```

`MultiXML.parse` returns `{}` for empty and whitespace-only inputs instead of
raising, so a missing or blank payload is observable as an empty hash rather
than an exception. When parsing invalid XML, MultiXML will throw a
`MultiXML::ParseError`.

```ruby
begin
  MultiXML.parse("<open></close>")
rescue MultiXML::ParseError => exception
  exception.xml    #=> "<open></close>"
  exception.cause  #=> Nokogiri::XML::SyntaxError: ...
end
```

### Deprecated in 0.9.0

The module constant, the primary parse entry point, and the
symbolize-keys option were renamed to align MultiXML with MultiJSON
and Ruby stdlib `JSON.parse`. The old names still work in 0.x but
now emit a one-time deprecation warning; they will be removed in 1.0.

| Deprecated                    | Use instead                     |
| ----------------------------- | ------------------------------- |
| `MultiXml` (constant)         | `MultiXML` (all-caps)           |
| `MultiXML.load(xml)`          | `MultiXML.parse(xml)`           |

The `MultiXml` constant (CamelCase) continues to work as a thin
delegator; every method call, constant lookup, and rescue clause
routes through `MultiXML` transparently.

`ParseError` instances expose `xml` and `cause` readers. `xml` contains the
input that caused the problem; `cause` contains the original exception raised
by the underlying parser.

### Writing a custom parser

A custom parser is any class (or module) that responds to two class methods:

```ruby
class MyParser
  def self.parse(io, namespaces: :strip)
    # parse the IO-like object into a Hash, raising ParseError on failure
  end

  def self.parse_error
    MyParser::ParseError
  end
end

MultiXML.parser = MyParser
```

`parse_error` is required: `MultiXML.parse` rescues `MyParser.parse_error`
to wrap parse failures in `MultiXML::ParseError`. The built-in parsers in
`lib/multi_xml/parsers/` are working examples.

MultiXML tries to have intelligent defaulting. If any supported library is
already loaded, MultiXML uses it before attempting to load others. When no
backend is preloaded, MultiXML walks its preference list and uses the first
one that loads successfully:

1. [`ox`][ox]
2. [`libxml-ruby`][libxml-ruby]
3. [`nokogiri`][nokogiri]
4. [`rexml`][rexml]
5. [`oga`][oga]

This order is a best-effort historical ranking by typical parse throughput on
representative workloads, not a guaranteed benchmark. Real-world performance
depends on the document shape and the Ruby implementation. REXML is a Ruby
default gem, so it's always available as a last-resort fallback on any
supported Ruby. If you have a workload where a different backend is faster,
set it explicitly with `MultiXML.parser = :your_parser`.

## Supported Ruby Versions

This library aims to support and is [tested against](https://github.com/sferik/multi_xml/actions/workflows/tests.yml) the following Ruby
implementations:

- Ruby 3.2
- Ruby 3.3
- Ruby 3.4
- Ruby 4.0

If something doesn't work in one of these implementations, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver]. Violations
of this scheme should be reported as bugs. Specifically, if a minor or patch
version is released that breaks backward compatibility, that version should be
immediately yanked and/or a new version should be immediately released that
restores compatibility. Breaking changes to the public API will only be
introduced with new major versions. As a result of this policy, you can (and
should) specify a dependency on this gem using the [Pessimistic Version
Constraint][pvc] with two digits of precision. For example:

```ruby
spec.add_dependency "multi_xml", "~> 0.9"
```

## Copyright

Copyright (c) 2010-2026 Erik Berlin. See [LICENSE][license] for details.

[docs]: https://github.com/sferik/multi_xml/actions/workflows/docs.yml
[gem]: https://rubygems.org/gems/multi_xml
[libxml-ruby]: https://github.com/xml4r/libxml-ruby
[license]: LICENSE.md
[linter]: https://github.com/sferik/multi_xml/actions/workflows/linter.yml
[mutant]: https://github.com/sferik/multi_xml/actions/workflows/mutant.yml
[nokogiri]: https://nokogiri.org/
[oga]: https://gitlab.com/yorickpeterse/oga
[ox]: https://github.com/ohler55/ox
[pvc]: http://docs.rubygems.org/read/chapter/16#page74
[rexml]: https://github.com/ruby/rexml
[semver]: http://semver.org/
[tests]: https://github.com/sferik/multi_xml/actions/workflows/tests.yml
[typecheck]: https://github.com/sferik/multi_xml/actions/workflows/typecheck.yml
