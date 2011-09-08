# MultiXML
A generic swappable back-end for XML parsing

## <a name="installation">Installation</a>
    gem install multi_xml

## <a name="documentation">Documentation</a>
[http://rdoc.info/gems/multi_xml](http://rdoc.info/gems/multi_xml)

## <a name="ci">Continuous Integration</a>
[![Build Status](https://secure.travis-ci.org/sferik/multi_xml.png)](http://travis-ci.org/sferik/multi_xml)

## <a name="examples">Usage Examples</a>
Lots of Ruby libraries utilize XML parsing in some form, and everyone has their
favorite XML library. In order to best support multiple XML parsers and
libraries, <tt>multi_xml</tt> is a general-purpose swappable XML backend
library. You use it like so:

    require 'multi_xml'

    MultiXml.parser = :libxml
    MultiXml.parser = MultiXml::Parsers::Libxml # Same as above
    MultiXml.parse('<tag>This is the contents</tag>') # Parsed using LibXML

    MultiXml.parser = :nokogiri
    MultiXml.parser = MultiXml::Parsers::Nokogiri # Same as above
    MultiXml.parse('<tag>This is the contents</tag>') # Parsed using Nokogiri

    MultiXml.parser = :ox
    MultiXml.parser = MultiXml::Parsers::Ox # Same as above
    MultiXml.parse('<tag>This is the contents</tag>') # Parsed using Ox

    MultiXml.parser = :rexml
    MultiXml.parser = MultiXml::Parsers::Rexml # Same as above
    MultiXml.parse('<tag>This is the contents</tag>') # Parsed using REXML

The <tt>parser</tt> setter takes either a symbol or a class (to allow for custom XML parsers) that
responds to <tt>.parse</tt> at the class level.

MultiXML tries to have intelligent defaulting. That is, if you have any of the supported parsers
already loaded, it will utilize them before attempting to load any. When loading, libraries are
ordered by speed: first LibXML, then Nokogiri, then Ox, then REXML.

## <a name="contributing">Contributing</a>
In the spirit of [free
software](http://www.fsf.org/licensing/essays/free-sw.html), **everyone** is
encouraged to help improve this project.

Here are some ways *you* can contribute:

* by using alpha, beta, and prerelease versions
* by reporting bugs
* by suggesting new features
* by writing or editing documentation
* by writing specifications
* by writing code (**no patch is too small**: fix typos, add comments, clean up inconsistent whitespace)
* by refactoring code
* by resolving [issues](https://github.com/sferik/multi_xml/issues)
* by reviewing patches

## <a name="issues">Submitting an Issue</a>
We use the [GitHub issue tracker](https://github.com/sferik/multi_xml/issues)
to track bugs and features. Before submitting a bug report or feature request,
check to make sure it hasn't already been submitted. You can indicate support
for an existing issuse by voting it up. When submitting a bug report, please
include a [Gist](https://gist.github.com/) that includes a stack trace and any
details that may be necessary to reproduce the bug, including your gem version,
Ruby version, and operating system. Ideally, a bug report should include a pull
request with failing specs.

## <a name="pulls">Submitting a Pull Request</a>
1. Fork the project.
2. Create a topic branch.
3. Implement your feature or bug fix.
4. Add documentation for your feature or bug fix.
5. Run <tt>bundle exec rake doc:yard</tt>. If your changes are not 100% documented, go back to step 4.
6. Add specs for your feature or bug fix.
7. Run <tt>bundle exec rake spec</tt>. If your changes are not 100% covered, go back to step 6.
8. Commit and push your changes.
9. Submit a pull request. Please do not include changes to the gemspec, version, or history file. (If you want to create your own version for some reason, please do so in a separate commit.)

## <a name="rubies">Supported Rubies</a>
This library aims to support and is [tested
against](http://travis-ci.org/sferik/multi_xml) the following Ruby
implementations:

* Ruby 1.8.7
* Ruby 1.9.1
* Ruby 1.9.2
* [JRuby](http://www.jruby.org/)
* [Rubinius](http://rubini.us/)
* [Ruby Enterprise Edition](http://www.rubyenterpriseedition.com/)

If something doesn't work on one of these interpreters, it should be considered
a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be personally responsible for providing patches in a
timely fashion. If critical issues for a particular implementation exist at the
time of a major release, support for that Ruby version may be dropped.

## <a name="inspiration">Inspiration</a>
MultiXML was inspired by [MultiJSON](https://github.com/intridea/multi_json/).

## <a name="copyright">Copyright</a>
Copyright (c) 2010 Erik Michaels-Ober.
See [LICENSE](https://github.com/sferik/multi_xml/blob/master/LICENSE.md) for details.
