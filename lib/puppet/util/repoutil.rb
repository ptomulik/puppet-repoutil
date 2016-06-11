require 'puppet'
require 'puppet/util'
require 'puppet/provider'

module Puppet::Util

  class RepoUtil < ::Puppet::Provider

    # TODO: write documentation for Puppet::Util::RepoUtil.package_name_regexp
    def self.package_name_regexp
      raise NotImplementedError, "this method should be overriden"
    end

    # TODO: write documentation for Puppet::Util::RepoUtil.package_prefix_regexp
    def self.package_prefix_regexp
      raise NotImplementedError, "this method should be overriden"
    end

    def self.validate_package_name(package)
      unless package =~ /^#{package_name_regexp}$/
        raise ArgumentError, "ill-formed package name '#{package}'"
      end
    end

    def self.validate_package_prefix(prefix)
      unless prefix =~ /^#{package_prefix_regexp}$/
        raise ArgumentError, "ill-formed package name prefix '#{prefix}'"
      end
    end

    # TODO: write documentation for Puppet::Util::RepoUtil.package_name_to_pattern
    def self.package_name_to_pattern(package)
      raise NotImplementedError, "this method should be overriden"
    end

    def self.package_prefix_to_pattern(prefix)
      raise NotImplementedError, "this method should be overriden"
    end

    def self.candidates_cache
      @candidates_cache ||= {}
    end

    def self.records_cache
      @records_cache ||= {}
    end

    def self.clear_candidates_cache()
      @candidates_cache = {}
    end

    def self.clear_records_cache()
      @records_cache = {}
    end

    def self.retrieve_candidates(pattern)
      raise NotImplementedError, "this method should be overriden"
    end

    def self.retrieve_records(pattern)
      raise NotImplementedError, "this method should be overriden"
    end

    def self.package_records(package)
      if (records = records_cache[package]).nil?
        validate_package_name(package)
        retrieve_records(package_name_to_pattern(package))
        records = records_cache[package]
      end
      records
    end

    def self.package_versions(package)
      records = package_records(package)
      records.nil? ? nil : records.keys
    end

    def self.package_candidate(package)
      if (candidate = candidates_cache[package]).nil?
        validate_package_name(package)
        retrieve_candidates(package_name_to_pattern(package))
        candidate = candidates_cache[package]
      end
      candidate
    end

    # TODO: write documentation for Puppet::Util::RepoUtil.packages_with_prefix
    def self.packages_with_prefix(prefix)
      package_candidates_with_prefix(prefix).keys
    end

    # TODO: write documentation for Puppet::Util::RepoUtil.package_versions_with_prefix
    def self.package_versions_with_prefix(prefix)
      Hash[ package_records_with_prefix(prefix).map { |k,r| [k, r.keys] }]
    end

    # TODO: write documentation for Puppet::Util::RepoUtil.package_candidates_with_prefix
    def self.package_candidates_with_prefix(prefix)
      validate_package_prefix(prefix)
      retrieve_candidates(package_prefix_to_pattern(prefix))
    end

    # TODO: write documentation for Puppet::Util::RepoUtil.package_records_with_prefix
    def self.package_records_with_prefix(prefix)
      validate_package_prefix(prefix)
      retrieve_records(package_prefix_to_pattern(prefix))
    end

  end

  # TODO: write documentation for RepoUtils class
  class RepoUtils

    require 'puppet/util/classgen'
    require 'puppet/util/autoload'
    class << self
      include Puppet::Util::ClassGen
    end

    @@repoutil_hash ||= {}

    def self.newrepoutil(name, options = {}, &block)
      unless options.is_a?(Hash)
        raise ArgumentError,
          "second argument must be a hash, not #{options.inspect}"
      end

      name = name.intern

      if unrepoutil(name)
        Puppet.debug "Reloading #{name} #{self.name} repoutil"
      end

      parent = if pname = options[:parent]
        options.delete(:parent)
        if pname.is_a? Class
          pname
        else
          if repoutil = self.repoutil(pname)
            repoutil
          else
            raise Puppet::DevError,
              "Could not find parent repoutil #{pname} of #{name}"
          end
        end
      else
        Puppet::Util::RepoUtil
      end

      options[:resource_type] ||= Puppet::Util::RepoUtil

      klass = genclass(
        name,
        :parent => parent,
        :overwrite => true,
        :hash => @@repoutil_hash,
        :attributes => options,
        &block
      )
    end

    def self.unrepoutil(name)
      name = name.intern
      if @defaultrepoutil and @defaultrepoutil.name.equal?(name)
        @defaultrepoutil = nil
      end

      rmclass(name, :hash => @@repoutil_hash)
    end

    def self.repoutil(name)
      return @@repoutil_hash[name] if @@repoutil_hash[name]

      # try mangling the name if it is a string
      if name.is_a?(String)
        name = name.downcase.intern
      end

      # Try loading the type
      if Gem::Version.new(Puppet.version) < Gem::Version.new('3.5.0')
        current_environment = Puppet::Node::Environment.current
      else
        current_environment = Puppet.lookup(:current_environment)
      end
      if repoutilloader.load(name, current_environment)
        Puppet.warning "Loaded puppet/util/repoutil/#{name} but no class was created" unless @@repoutil_hash.include? name
      end

      return @@repoutil_hash[name]
    end

    def self.repoutils
      loadall if @@repoutil_hash.empty?
      @@repoutil_hash.keys
    end

    def self.suitablerepoutils
      loadall if @@repoutil_hash.empty?
      @@repoutil_hash.find_all { |name, repoutil|
        repoutil.suitable?
      }.collect { |name, repoutil|
        repoutil
      }.reject { |p| p.name == :fake } # For testing
    end

    def self.defaultrepoutil
      return @defaultrepoutil if @defaultrepoutil

      suitable = suitablerepoutils

      # Find which repoutils are a default for this system.
      defaults = suitable.find_all { |repoutil| repoutil.default? }

      # If we don't have any default we use suitable repoutils
      defaults = suitable if defaults.empty?
      max = defaults.collect { |repoutil| repoutil.specificity }.max
      defaults = defaults.find_all { |repoutil| repoutil.specificity == max }

      if defaults.length > 1
        Puppet.warning(
          "Found multiple default repoutils for #{self.name}: #{defaults.collect { |i| i.name.to_s }.join(", ")}; using #{defaults[0].name}"
        )
      end

      @defaultrepoutil = defaults.shift unless defaults.empty?
    end

    def self.loadall
      repoutilloader.loadall
    end

    def self.repoutilloader
      unless defined?(@@repoutilloader)
        args = {}
        if Gem::Version.new(Puppet::version) < Gem::Version.new('4.0.0')
          args[:wrap] = false
        end
        @@repoutilloader = Puppet::Util::Autoload.new(self, "puppet/util/repoutil", args)
      end
      @@repoutilloader
    end

    def self.collective_query(opname, subjects, utils)
      opname = opname.intern
      subjects = [ subjects ] if not subjects.is_a?(Array)
      utils = utils.map { |u| u.respond_to?(opname) ? u : repoutil(u.intern) }
      hash = Hash[ utils.map { |u|
        [
          u.name, Hash[ subjects.map { |p|
            [p, u.method(opname).call(p)]
          }.reject{ |p, r| r.nil? } ]
        ]
      }]
    end

    def self.collective_search_hash(opname, filters, utils)
      opname = opname.intern
      filters = [ filters ] if not filters.is_a?(Array)
      utils = utils.map { |u| u.respond_to?(opname) ? u : repoutil(u.intern) }

      hash = {}
      utils.each do |u|
        hash[u.name] ||= {}
        filters.each do |f|
          hash[u.name].merge!( u.method(opname).call(f) )
        end
      end
      hash
    end

    def self.collective_search_array(opname, filters, utils)
      opname = opname.intern
      filters = [ filters ] if not filters.is_a?(Array)
      utils = utils.map { |u| u.respond_to?(opname) ? u : repoutil(u.intern) }

      hash = {}
      utils.each do |u|
        hash[u.name] ||= []
        filters.each do |f|
          hash[u.name] += u.method(opname).call(f)
        end
      end
      hash
    end

    # TODO: write docs for Puppet::Util::RepoUtils.package_records
    def self.package_records(packages, utils = suitablerepoutils)
      collective_query(:package_records, packages, utils)
    end

    # TODO: write docs for Puppet::Util::RepoUtils.package_versions
    def self.package_versions(packages, utils = suitablerepoutils)
      collective_query(:package_versions, packages, utils)
    end

    # TODO: write docs for Puppet::Util::RepoUtils.package_candidates
    def self.package_candidates(packages, utils = suitablerepoutils)
      collective_query(:package_candidates, packages, utils)
    end

    # TODO: write docs for Puppet::Util::RepoUtils.package_candidates
    def self.packages_with_prefixes(prefixes, utils = suitablerepoutils)
      collective_search_array(:packages_with_prefix, prefixes, utils)
    end

    # TODO: write docs for Puppet::Util::RepoUtils.package_candidates
    def self.package_records_with_prefixes(prefixes, utils = suitablerepoutils)
      collective_search_hash(:package_records_with_prefix, prefixes, utils)
    end

    # TODO: write docs for Puppet::Util::RepoUtils.package_candidates
    def self.package_versions_with_prefixes(prefixes, utils = suitablerepoutils)
      collective_search_hash(:package_versions_with_prefix, prefixes, utils)
    end

    # TODO: write docs for Puppet::Util::RepoUtils.package_candidates
    def self.package_candidates_with_prefixes(prefixes, utils = suitablerepoutils)
      collective_search_hash(:package_candidates_with_prefix, prefixes, utils)
    end

  end

  def self.newrepoutil(name, options = {}, &block)
    Puppet::Util::RepoUtils.newrepoutil(name, options, &block)
  end

  def self.repoutil(name)
    Puppet::Util::RepoUtils.repoutil(name)
  end

  def self.repoutils
    Puppet::Util::RepoUtils.repoutils
  end

  def self.suitablerepoutils
    Puppet::Util::RepoUtils.suitablerepoutils
  end

  def self.defaultrepoutil
    Puppet::Util::RepoUtils.defaultrepoutil
  end

end
