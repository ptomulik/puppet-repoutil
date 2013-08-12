module Puppet::Util
  newrepoutil(:apt) do

    commands :aptcache => '/usr/bin/apt-cache'
    defaultfor :operatingsystem => [:debian, :ubuntu]

    def self.package_name_regexp
      /[a-z0-9][a-z0-9\.+-]+/
    end

    def self.package_prefix_regexp
      /(?:[a-z0-9][a-z0-9\.+-]*)?/
    end

    def self.escape_package_name(package)
      package.gsub(/([\.\+])/) {|c| '\\' + c} 
    end

    def self.escape_package_prefix(prefix)
      prefix.gsub(/([\.\+])/) {|c| '\\' + c} 
    end

    def self.package_name_to_pattern(package)
      "^#{escape_package_name(package)}$"
    end

    def self.package_prefix_to_pattern(prefix)
      "^#{escape_package_prefix(prefix)}"
    end

    def self.show_policies(pattern)
      aptcache '-q=2', '-a', 'policy', pattern
    end

    def self.show_records(pattern)
      aptcache '-q=2', '-a', 'show', pattern
    end

    def self.retrieve_candidates(pattern)
      begin
        output = show_policies(pattern)
      rescue Puppet::ExecutionFailure => err
        # NOTE: we may wish to implement reaction to failures at some point
        raise err unless err.message =~ /No packages found/
        {}
      else
        candidates = {}
        package = nil
        output.each_line do |line|
          line.match(/^(#{package_prefix_regexp}):\s*$/) { |m| 
            package = m.captures[0] 
          }
          line.match(/^\s+Candidate:\s*(\S+)\s*$/) { |m|
            candidate = m.captures[0]
            if package and candidate and (not candidate.match(/^\(none\)$/)) 
              candidates[package] = candidate
              package = nil
            end
          }
        end
        candidates_cache.merge!(candidates)
        candidates
      end
    end

    def self.retrieve_records(pattern)
      begin
        output = show_records(pattern).chomp
      rescue Puppet::ExecutionFailure => err
        # NOTE: we may wish to implement reaction to failures at some point
        raise err unless err.message =~ /No packages found/
        {}
      else
        # update candidates cache
        candidates = retrieve_candidates(pattern)

        fn_re = /[A-Za-z][A-Za-z0-9_-]*/ # field name
        fv_re = /\S.*(?:\r?\n(?:(?:\s*\.\s*)|(?:\s+\S.*)))*/ # field value
        re = /^(#{fn_re})\s*:\s*(#{fv_re})\s*$/

			  paragraphs = output.split(/\n\n+/) 
        records = paragraphs.reject { |para| 
          ((not para.match(/^Package:/)) or (not para.match(/^Version:/)))
        }.map { |para| 
          para.scan(re).map {|cs| cs[0..1]}
        }.map { |pairs| 
          Hash[pairs]
        }

        hash = {}
        records.each do |record|
          package = record['Package'].chomp
          version = record['Version'].chomp
          hash[package] ||= {}
          hash[package][version] = record
        end

        # delete records having no installation candidate
        hash.delete_if { |package, phash| not candidates.include?(package) }

        records_cache.merge!(hash)

        hash
      end
    end

  end
end
