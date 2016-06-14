# ptomulik-repoutil

[![Build Status](https://travis-ci.org/ptomulik/puppet-repoutil.svg?branch=master)](https://travis-ci.org/ptomulik/puppet-repoutil)
[![Coverage Status](https://coveralls.io/repos/github/ptomulik/puppet-repoutil/badge.svg?branch=master)](https://coveralls.io/github/ptomulik/puppet-repoutil?branch=master)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What repoutil affects](#what-[modulename]-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with repoutil](#beginning-with-repoutil)
4. [Usage](#usage)
5. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)

## Overview

Puppet utilities to interact with package repositories. Simplify tasks such
as obtaining lists of packages available for installation, their versions,
installation candidates and so on. This plugin may be handy, if you need to
implement facts describing packages available to agents' via their package
repositories.

## Module Description

The module provides means to access meta-information from package repositories
such as apt. The supported operations currently include:

  * listing available packages,
  * listing available package(s) versions,
  * retrieving full package records (containing descriptions, etc.),
  * determining installation candidate (version) for a given package,

The module currently supports the following providers:

  * apt, aptitude (Debian),
  * ports (FreeBSD)

Utilities provided by `repoutil` are devoted to developers of other modules,
and are not intended to be used directly from puppet manifests.

## Setup

### What repoutil affects

  * it executes CLI commands necessary to query information from package
    repositories. The exact list of commands being executed depend on agent's OS
    and module's usage, but generally they should be regarded as read-only.

    The following CLI commands are currently used by `repoutil`'s:

    - on Debian: `apt-cache show|policy`, `aptitude show`,
    - on FreeBSD, OpenBSD, NetBSD:  `make -C /path/to/ports search`,

### Setup Requirements

You may need to enable **pluginsync** in your *puppet.conf*.

### Beginning with repoutil

First, include module file:

    require 'puppet/util/repoutil'

Once the module file is included you may obtain reference to repoutil provider
(call it `repo`), which implements access to a particular repository type. For
example, apt `repo` may be obtained as follows:

    repo = Puppet::Util.repoutil(:apt)

The `:apt` utility is **suitable** for use on Debian or Ubuntu. For other
systems we should choose other facility. You may also load default utility for
current environment:

    repo = Puppet::Util.defaultrepoutil

Once we have obtained `repo`, we may request information from that repository.
For example, we may wish to list all packages with names starting with
'apache':

    apaches = repo.packages_with_prefix('apache')

This would return an array of all available package names starting with
'apache' prefix, for example:

    ["apache2-utils", "apache2-mpm-prefork", "apache2-mpm-worker", ... ]

There are also other methods. For example:

    apache_versions = repo.package_versions_with_prefix('apache')

would return a hash with keys being the package names (from previous example)
and arrays of available versions as values:

    {
      "apache2"             => ["2.4.6-2", "2.2.22-13"],
      "apache2-mpm-prefork" => ["2.4.6-2", "2.2.22-13"],
      "apache2-mpm-itk"     => ["2.4.6-2", "2.2.22-13"],
      . . .
    }

To retrieve full records from package database (including version, description,
and other information) you may use:

    apache_records = repo.package_records_with_prefix('apache')

This would return a hash such as the following:

    {
      "apache2" => {
        "2.4.6-2" => {
          "Package"=>"apache2",
          "Version"=>"2.4.6-2",
          "Installed-Size"=>"481",
          . . .
        },
        "2.2.22-13" => {
          "Package"=>"apache2",
          "Version"=>"2.2.22-13",
          "Installed-Size"=>"29",
          . . .
        }
      },

      "apache2-mpm-prefork => {
        . . .
      },

      .
      .
      .
    }

We also may operate on exact package names, that is we may request information
for one particular package. For example, in order to obtain available package
versions we call:

    apache2_versions = repo.package_versions('apache2')

This method returns an array, such as `["2.4.6-2", "2.2.22-13"]` or `nil` (if
there is no database entry for the package).

To see the installation candidate for package (what version of the package
would be installed if we requested package installation/upgrade), we do:

    apache2_candidates = repo.package_candidate('apache2')

This returns a string (e.g. `"2.4.6-2"`) or `nil` (if there is no such package
in repository).


To retrieve full records for available package versions we type:

    apache2_records = repo.package_records('apache2')

This should return a hash such as:

    {
      "2.4.6-2" =>
      {
        "Package"=>"apache2",
        "Version"=>"2.4.6-2",
        "Installed-Size"=>"481",
        . . .
      },
      "2.2.22-13" =>
      {
        "Package"=>"apache2",
        "Version"=>"2.2.22-13",
        "Installed-Size"=>"29",
        . . .
      }
    }

In case there is no such package in repository, `nil` is returned.

## Usage

The module consists of two ruby classes:

  - [`Puppet::Util::RepoUtil`](#methods-within-puppetutilrepoutil-class) -
    represents single utility,
  - [`Puppet::Util::RepoUtils`](#methods-within-puppetutilrepoutils-class) -
    represents the "registry" of available utilities,

and few [shorthand module-level methods](#methods-within-puppetutil-module).

The [`Puppet::Util::RepoUtil`](#methods-within-puppetutilrepoutil-class) class
abstracts CLI commands used to access repository cache/database and is
inherited by several sub-classes implementing particular types of repositories
(providers). The user actually operates on providers, that is on subclasses of
`Puppet::Util::RepoUtil`. Each *repoutil provider* shall correspond to an
appropriate [package provider](http://docs.puppetlabs.com/references/latest/type.html#package)
from puppet core (note, not all puppet providers are covered here). For
example, there is `Puppet::Util::RepoUtils::Apt` class (`:apt` repoutil) which
corresponds to `:apt` package provider. To retrieve appropriate repoutil, you
should use one of the methods from `Puppet::Util::RepoUtils` [described in
reference](#provider-management). [Methods within
`Puppet::Util::RepoUtil`](#methods-within-puppetutilrepoutil-class) (and
descendants) may be used to operate on a single repository.

[Methods within `Puppet::Util::RepoUtils`](#methods-within-puppetutilrepoutils-class)
are twofold. Some of them are provided to
[manage providers](#provider-management). These include
[`newrepoutil`](#newrepoutilname-options---block-1) (to implement new
providers), [`unrepoutil`](#unrepoutilname) (to unregister particular
provider), [`repoutils`](#repoutils-1) (to retrieve all available providers),
[`suitablerepoutils`](#suitablerepoutils-1) (to retrieve all the providers
suitable for the current environment), [`defaultrepoutil`](#defaultrepoutil-1)
to get provider default to current environment and
[`repoutil`](#repoutilname-1) (to retrieve particular provider). Other methods
within `Puppet::Util::RepoUtils` may be used to perform
[collective operations](#collective-operations-on-repositories)
on repositories. For example, [`package_candidates`](#package_candidatespackages)
may be used to retrieve lists of package candidates known to all the suitable
package repositories (this yields a hash of the form `{:apt => {...}, :aptitude
=> {...}, ...}`).

## Reference

### Methods within `Puppet::Util` module

##### newrepoutil(name, options = {}, &block)

Shorthand to [`Puppet::Util::RepoUtils.newrepoutil`](#newrepoutilname-options---block-1).

##### repoutil(name)

Shorthand to [`Puppet::Util::RepoUtils.repoutil`](#repoutilname-1).

##### repoutils

Shorthand to [`Puppet::Util::RepoUtils.repoutils`](#repoutils-1).

##### suitablerepoutils

Shorthand to [`Puppet::Util::RepoUtils.suitablerepoutils`](#suitablerepoutils-1).

##### defaultrepoutil

Shorthand to [`Puppet::Util::RepoUtils.defaultrepoutil`](#defaultrepoutil-1).


### Methods within `Puppet::Util::RepoUtils` class

#### Provider management

##### newrepoutil(name, options = {}, &block)

Define new repo provider. This is intended for developers/contributors and may
be used to add support for new repository types. For details about extending
repoutil module see [adding new utility](#adding-new-utility-provider).

##### unrepoutil(name)

Unload/unregister a repoutil provider created with [`newrepoutil(name)`](#newrepoutilname-1).

##### repoutil(name)

Retrieve repoutil provider identified by `name`. The provider must be first
created with [`newrepoutil(name, ...)`](#newrepoutilname-options--block-1).

*Example:*

    repo = Puppet::Util::RepoUtils.repoutil(:apt)
    candidate = repo.package_candidate('apache2')

##### repoutils

Retrieve all existing repoutil providers (includes also those not suitable for
a given environment).

*Example:*

    repos = Puppet::Util::RepoUtils.repoutils
    apache2_candidates = {}
    repos.each do |repo|
      if repo.suitable?
        apache2_candidates[repo] = repo.package_candidate('apache2')
      end
    end

##### suitablerepoutils

Retrieve all repoutil providers suitable for the current environment.

*Example:*

    repos = Puppet::Util::RepoUtils.suitablerepoutils
    apache2_candidates = {}
    repos.each do |repo|
      apache2_candidates[repo] = repo.package_candidate('apache2')
    end

##### defaultrepoutil

Retrieve repoutil provider that is default to current environment.

*Example:*

    repo = Puppet::Util::RepoUtils.defaultrepoutil
    candidates = repo.package_candidate('apache2')

##### loadall

For internal use.

##### repoutilloader

For internal use.

#### Collective operations on repositories

##### package\_records(packages, utils = suitablerepoutils)

Return package records obtained from multiple sources. This function performs
query on multiple repositories at once. It may be used to gather package
information from multiple repository types available to the local system.

Arguments:

  * `packages` - package name (exact) or an array of (exact) package names,
  * `utils` - array with repoutil providers to be queried (optional).

*Example*:

    records = Puppet::Util::RepoUtils.package_records('apache2')

Would return a hash of the form:

    {
      :aptitude =>
      {
        'apache2' =>
        {
          '2.2.13-2' => { 'Package' => 'apache2', 'Version' => '2.2.13-2', ... }
          '2.4.6-2'  => { ... }
        }
      },
      :apt  =>
      {
        'apache2' =>
        {
          '2.2.13-2' => { ... },
          '2.4.6-2'  => { ... }
        }
      },
       ...
     }

where `:apt`, `:aptitude`, ..., are keys corresponding to repoutil providers
listed in `utils`.

##### package\_versions(packages, utils = suitablerepoutils)

Return package versions available from multiple sources. This function performs
query on multiple repositories at once. It may be used to gather package
information from multiple repository types available to the local system.

Arguments:

  * `packages` - package name (exact) or an array of (exact) package names,
  * `utils` - array with repoutil providers to be queried (optional).

*Example*:

    versions = Puppet::Util::RepoUtils.package_versions(['apache2', 'apache2-dev'])

Would return a hash of the form:

    {
      :aptitude =>
      {
        "apache2"     =>  ["2.4.6-2"],
        "apache2-dev" =>  ["2.4.6-2"]
      },
      :apt =>
      {
        "apache2"     =>  ["2.4.6-2", "2.2.22-13"],
        "apache2-dev" =>  ["2.4.6-2"]
      }
    }

where `:apt`, `:aptitude`, ..., are keys corresponding to repoutil providers
listed in `utils`.


##### package\_candidates(packages, utils = suitablerepoutils)

Return package candidates available for installation from multiple sources.
This function may perform query on multiple repositories at once. It may be
used to gather package information from multiple repository types available to
the local system.

Arguments:

  * `packages` - package name (exact) or an array of (exact) package names,
  * `utils` - array with repoutil providers to be queried (optional).

*Example*:

    candidates = Puppet::Util::RepoUtils.package_candidates(['apache2', 'apache2-dev'])

would return a hash of the form:

    {
      :aptitude => { "apache2" => "2.4.6-2", "apache2-dev" => "2.4.6-2" },
      :apt      => { "apache2" => "2.4.6-2", "apache2-dev" => "2.4.6-2" }
    }

where `:apt`, `:aptitude`, ..., are keys corresponding to repoutil providers
listed in `utils`.

##### packages\_with\_prefixes(prefixes, utils = suitablerepoutils)

Search multiple repositories for packages having names starting with (one of
the) prefixes. This function may perform search on multiple repositories at
once. It may be used to gather package information from multiple repository
types available to the local system.

Arguments:

  * `prefixes` - prefix or an array of prefixes to be matched against package names,
  * `utils` - array with repoutil providers to be queried (optional).

*Example*:

    names = Puppet::Util::RepoUtils.packages_with_prefixes(['postfix', 'apache2'])

would return a hash of the form:

    {
      :apt      => ["postfix-policyd-spf-python", "postfix-cdb", ..., "apache2", "apache2-data", ... ],
      :aptitude => ["postfix-policyd-spf-python", "postfix-cdb", ..., "apache2", "apache2-data", ... ]
    }

##### package\_records\_with\_prefixes(prefixes, utils = suitablerepoutils)

Search multiple repositories for packages having names starting with (one of
the) prefixes and return their full records. This function may perform search
on multiple repositories at once. It may be used to gather package information
from multiple repository types available to the local system.

Arguments:

  * `prefixes` - prefix or an array of prefixes to be matched against package names,
  * `utils` - array with repoutil providers to be queried (optional).

Returns a hash with the form same as in
[`Puppet::Util::RepoUtils.package_records`](#package_recordspackages-utils--suitablerepoutils)

##### package\_versions\_with\_prefixes(prefixes, utils = suitablerepoutils)

Search multiple repositories for packages having names starting with (one of
the) prefixes and return their available versions. This function may perform
search on multiple repositories at once. It may be used to gather package
information from multiple repository types available to the local system.

Arguments:

  * `prefixes` - prefix or an array of prefixes to be matched against package names,
  * `utils` - array with repoutil providers to be queried (optional).

Returns a hash with the form same as in
[`Puppet::Util::RepoUtils.package_versions`](#package_versionspackages-utils--suitablerepoutils)

##### package\_candidates\_with\_prefixes(prefixes, utils = suitablerepoutils)

Search multiple repositories for packages having names starting with (one of
the) prefixes and return their installation candidates. This function may
perform search on multiple repositories at once. It may be used to gather
package information from multiple repository types available to the local
system.

Arguments:

  * `prefixes` - prefix or an array of prefixes to be matched against package names,
  * `utils` - array with repoutil providers to be queried (optional).

Returns a hash with the form same as in
[`Puppet::Util::RepoUtils.package_candidates`](#package_candidatespackages-utils--suitablerepoutils)

### Methods within `Puppet::Util::RepoUtil` class

##### package\_name\_regexp

Regular expression to match package names. Used for validation of input
arguments ([`validate_package_name`](#validate_package_namepackage)) by
functions having `package` argument and to parse output from CLI commands.

##### package\_prefix\_regexp

Regular expression to match package prefixes. Used for validation of input
arguments ([`validate_package_prefix`](#validate_package_prefixprefix)) by
functions having `prefix` argument.

##### validate\_package\_name(package)

Throw an `ArgumentError` exception if `package` doesn't match the
`package_name_regexep`.

##### validate\_package\_prefix(prefix)

Throw an `ArgumentError` exception if `prefix` doesn't match the
`package_prefix_regexep`.

##### package\_name\_to\_pattern(package)

Convert `package` name to a pattern for use by `retrieve_records` or
`retrieve_candidates`.

##### package\_prefix\_to\_pattern(package)

Convert package `prefix` to a pattern for use by `retrieve_records` or
`retrieve_candidates`.

##### candidates\_cache

Hash containing package candidates already seen by provider. The format is

    {
      'package1' => 'ver1',
      'package2' => 'ver1',
      ...
    }

Certain methods operating on exact package names, such as
[`package_candidate`](#pacakge_candidatepackage), are searching this cache
first and launchning external CLI tools only if the record is not found in this
cache.

##### records\_cache

Hash containing package records already seen by provider. The format is

    {
      'package1' =>
      {
        'ver1' => { 'Field1' => 'Text1', 'Field2' => 'Text2', ... },
        'ver2' => { 'Field1' => 'Text1', 'Field2' => 'Text2', ... },
        ...
      },
      'package2' =>
      {
        'ver1' => { 'Field1' => 'Text1', 'Field2' => 'Text2', ... },
        'ver2' => { 'Field1' => 'Text1', 'Field2' => 'Text2', ... },
        ...
      },
      ...
    }

Certain methods operating on exact package names, such as
[`package_record`](#pacakge_recordpackage) are searching this cache first and
launching external CLI tools only if the record is not found in the cache.

##### clear\_candidates\_cache

Clear [`candidates_cache`](#candidates_cache).

##### clear\_records\_cache

Clear [`records_cache`](#records_cache).

##### retrieve\_candidates(pattern)

Retrieve information about package candidates from external source (CLI
command). This method shall also update [`candidates_cache`](#candidates_cache)
and may also update the [`records_cache`](#records_cache). The `pattern`
argument is a string containig tool-specific pattern used to search repository
database - for example in `:apt` provider this is a pattern for
`apt-cache policy` command.

##### retrieve\_records(pattern)

Retrieve package records from external source (CLI command). This method shall
also update [`records_cache`](#records_cache) and may also update the
[`candidates_cache`](#candidates_cache). The `pattern` argument is a string
containing tool-specific pattern used to search repository database - for
example in `:apt` provider this is a pattern for `apt-cache show` command.

##### package\_records(package)

Return package records describing given package. The `package` argument shall
be an exact package name. The returned hash has the following form

    {
      'ver1' => { 'Field1' => 'Text1', 'Field2' => 'Text2' },
      'ver2' => { 'Field1' => 'Text1', 'Field2' => 'Text2' },
      ...
    }

If `package` is not found in repository, `nil` is returned.

##### package\_versions(package)

Return package versions available for installation. The `package` argument shall
be an exact package name. The method returns an array containing available
versions.

    [ 'ver1', 'ver2', ... ]

If `package` is not found in repository, `nil` is returned.

##### package\_candidate(package)

Return `package`'s installation candidate. The `package` argument shall be an
exact package name. The method returns a string containing version number of
the installation candidate. If `package` is not found in repository, `nil` is
returned.

##### packages\_with\_prefix(prefix)

List package names for all available packages having name starting with `prefix`.

##### package\_versions\_with\_prefix(prefix)

Return package versions for all available packages having name starting with
`prefix`. The function returns a hash in the form

    {
      'packageA' => ['verA1', 'verA2', ...],
      'packageB' => ['verB1', 'verB2', ...],
    }

If there is no package matching the prefix, an empty hash is returned.

##### package\_candidates\_with\_prefix(prefix)

Return package candidates for all available packages having name starting with
`prefix`. The function returns a hash in the form

    {
      'package1' => 'ver1',
      'package2' => 'ver2',
    }

##### package\_records\_with\_prefix(prefix)

Return full records for all available packages having name starting with
`prefix`. The function returns a hash in the form

    {
      'packageA' =>
      {
        'verA1' => { 'Field1' => 'Text1', 'Field2' => 'Text2', ... },
        'verA2' => { 'Field1' => 'Text1', 'Field2' => 'Text2', ... },
        ...
      },
      'packageB' =>
      {
        'verB1' => { 'Field1' => 'Text1', 'Field2' => 'Text2', ... },
        'verB2' => { 'Field1' => 'Text1', 'Field2' => 'Text2', ... },
        ...
      },
      ...
    }

If there is no package matching the prefix, an empty hash is returned.


## Limitations

  * Currently supports only Debian/Ubuntu *apt*, *aptitude* and FreeBSD *ports*
  * Some tests are missing.

## Development

The project is held on github:

  https://github.com/ptomulik/puppet-repoutil

Feel free to submit bug reports, feature requests or to create pull requests.

### Extending repoutil

#### Adding new utility (provider)

The new utility may be defined by using `Puppet::Util.newrepoutil` method.

  - `Puppet::Util.newrepoutil(name, options = {}, &block)`

If you're extending `repoutil` module, the source code of the new provider (say
`foo`) should go to file

  - `lib/puppet/util/repoutil/foo.rb`

You may also consider adding `:foo` entry to `utils` array in

  - `spec/unit/puppet/util/repoutil_spec.rb`

to enable common unit tests for your provider. Specific tests should be
implemented in

  - `spec/unit/puppet/util/repoutil/foo_spec.rb`

When defining new utility, one should define following methods in the block
provided to [`newrepoutil`](#newrepoutilname-options--block-1):

  - `self.package_name_regexp`
  - `self.package_prefix_regexp`
  - `self.package_name_to_pattern(package)`
  - `self.package_prefix_to_pattern(prefix)`
  - `self.retrieve_candidates(pattern)`
  - `self.retrieve_records(pattern)`

To configure suitability, confines, defaults etc., use [same methods as in
normal providers](http://docs.puppetlabs.com/guides/provider_development.html).

Example template for a repoutil `foo` is presented below:

    # lib/puppet/util/repoutil/foo.rb
    module Puppet::Util
      newrepoutil(:foo) do
        commands :foocmd => '/usr/bin/foo'

        def self.package_name_regexp
          # this is tool-specific, check if this pattern fits your needs
          /[a-z0-9][a-z0-9\.+-]+/
        end

        def self.package_prefix_regexp
          # this is tool-specific, check if this pattern fits your needs
          /(?:[a-z0-9][a-z0-9\.+-]*)?/
        end

        # escape characters that could be interpreted as meta-characters
        # by CLI commands used for repository lookups
        def self.escape_package_name(package)
          # this is tool-specific, check if this pattern fits your needs
          package.gsub(/([\.\+])/) {|c| '\\' + c}
        end

        # escape characters that could be interpreted as meta-characters
        # by CLI commands used for repository lookups
        def self.escape_package_prefix(prefix)
          # this is tool-specific, check if this pattern fits your needs
          prefix.gsub(/([\.\+])/) {|c| '\\' + c}
        end

        def self.package_name_to_pattern(package)
          # this is tool-specific, check if this conversion fits your needs
          "^#{escape_package_name(package)}$"
        end

        def self.package_prefix_to_pattern(prefix)
          # this is tool-specific, check if this conversion fits your needs
          "^#{escape_package_prefix(prefix)}"
        end

        def self.show_candidates(pattern)
          # adjust to the actual syntax of your CLI command
          foocmd 'candidates',  pattern
        end

        def self.show_records(pattern)
          # adjust to the actual syntax of your CLI command
          foocmd 'records', pattern
        end

        def self.retrieve_candidates(pattern)
          output = show_candidates(pattern).chomp
          # now, extract candidates from output, update candidates_cache and
          # return the extracted candidates
        end

        def self.retrieve_records(pattern)
          output = show_records(pattern).chomp
          # now, extract records from output, update records_cache and
          # return the extracted records
        end
      end
    end
