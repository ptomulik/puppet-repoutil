require 'facter'

module Puppet::Util
  newrepoutil(:ports) do

    if Facter.value('operatingsystem') == 'NetBSD'
      @portsdir = '/usr/pkgsrc'
    else
      @portsdir = '/usr/ports'
    end

    commands :make => '/usr/bin/make'
    confine :exists => @portsdir
    defaultfor :operatingsystem => [:freebsd, :openbsd, :netbsd]

    def self.package_name_regexp
      /[a-zA-Z0-9][a-zA-Z0-9_\.+-]*/
    end

    def self.package_prefix_regexp
      /(?:[a-zA-Z0-9][a-zA-Z0-9_\.+-]*)?/
    end

    def self.version_suffix_pattern
      '-[A-Za-z0-9][A-Za-z0-9\\.,_]*'
    end

    def self.escape_package_name(package)
      package.gsub(/([\.])/) {|c| '\\' + c} 
    end

    def self.escape_package_prefix(prefix)
      prefix.gsub(/([\.])/) {|c| '\\' + c} 
    end

    def self.package_name_to_pattern(package)
      "^#{escape_package_name(package)}(#{version_suffix_pattern})$"
    end

    def self.package_prefix_to_pattern(prefix)
      "^#{escape_package_prefix(prefix)}"
    end


    def self.show_records(pattern)
      make '-C', @portsdir, 'search', "name=#{pattern}"
    end

    def self.parse_records(string)
      begin
        paragraphs = string.split(/\n\n+/) 
      rescue ArgumentError => err
        # try handle non-ascii descriptions (see 'fr-belote' package i.e.) 
        raise err unless err.message =~ /invalid byte sequence/
        inenc = 'UTF-8' # assumed ad-hoc
        string.encode!('ASCII', inenc, {:invalid=>:replace, :undef=>:replace})
        paragraphs = string.split(/\n\n+/) 
      end

      fn_re = /[A-Za-z0-9_-]+/ # field name
      fv_re = /\S?.*\S/ # field value
      re = /^\s*(#{fn_re})\s*:\s*(#{fv_re})\s*$/

      records = paragraphs.reject { |para| 
        para.match(/^Moved:/) or (not para.match(/^Path:/)) or 
        (not para.match(/^Port:/))
      }.map { |para| 
        para.scan(re)
      }.map { |pairs| 
        Hash[pairs]
      }

      hash = {}
      records.each do |record|
        parts = record['Port'].split('-')
        package = parts.size >= 2 ? parts[0..-2].join('-') : parts[0]
        version = parts.size >= 2 ? parts.last : nil
        # if we're unable to extract version, nil will be used
        hash[package] ||= {}
        record.merge!({'Version' => version, 'Package' => package})
        hash[package][version] = record
      end
      hash
    end

    def self.extract_candidates(records)
      # we assume, that there is exactly one version per package in records
      Hash[records.map { |name, rs| [name, rs.first[0]] } ]
    end

    def self.retrieve_records_candidates(pattern, what)
      begin
        output = show_records(pattern)
      rescue Puppet::ExecutionFailure => err
        # NOTE: we may wish to implement reaction to failures at some point
        raise err
      else
        records = parse_records(output)
        candidates = extract_candidates(records)
        # actually we have information for both caches, so we update them
        records_cache.merge!(records)
        candidates_cache.merge!(candidates)
        # return what the user wants
        case what
        when /records/
          records
        when /candidates/
          candidates
        else
          raise ArgumentError, "second argument must be 'records' or 'candidates', not #{what}"
        end
      end
    end

    def self.retrieve_candidates(pattern)
      retrieve_records_candidates(pattern, 'candidates')
    end

    def self.retrieve_records(pattern)
      retrieve_records_candidates(pattern, 'records')
    end

  end
end
