require 'spec_helper'
require 'puppet/util/repoutil'

describe "Puppet::Util::RepoUtils" do
  [ :newrepoutil,
    :unrepoutil,
    :repoutil,
    :repoutils,
    :suitablerepoutils,
    :defaultrepoutil,
    :loadall,
    :repoutilloader,
    :package_records,
    :package_versions,
    :package_candidates,
    :packages_with_prefixes,
    :package_records_with_prefixes,
    :package_versions_with_prefixes,
    :package_candidates_with_prefixes,
  ].each do |method|
    it "should respond to #{method}" do
      Puppet::Util::RepoUtils.respond_to?(method).should == true
    end
  end
end

describe "Puppet::Util::RepoUtil" do

  utils = [
    :apt,
    :aptitude,
    :ports,
  ]

  it "should be a class derived from Puppet::Provider" do
    (Puppet::Util::RepoUtil < Puppet::Provider).should be_true
  end

  [ :package_name_regexp,
    :package_prefix_regexp,
    :validate_package_name,
    :validate_package_prefix,
    :package_name_to_pattern,
    :package_prefix_to_pattern,
    :candidates_cache,
    :records_cache,
    :clear_candidates_cache,
    :clear_records_cache,
    :retrieve_candidates,
    :retrieve_records,
    :package_records,
    :package_versions,
    :packages_with_prefix,
    :package_versions_with_prefix,
    :package_candidates_with_prefix,
    :package_records_with_prefix,
  ].each do |method|
    it "should respond to #{method}" do
      Puppet::Util::RepoUtil.respond_to?(method).should == true
    end
  end

  klass = Puppet::Util::RepoUtil
  { :package_name_regexp => lambda { klass.package_name_regexp },
    :package_prefix_regexp => lambda { klass.package_prefix_regexp },
    :package_name_to_pattern => lambda { klass.package_name_to_pattern('foo') },
    :package_prefix_to_pattern => lambda { klass.package_prefix_to_pattern('foo') },
    :retrieve_candidates => lambda { klass.retrieve_candidates('foo') },
    :retrieve_records => lambda { klass.retrieve_records('foo') },
  }.each do |name, method|
    it "#{name}('') should raise NotImplementedError" do
      method.should (raise_error NotImplementedError)
    end
  end

  utils.each do |name|

    context "repoutil(:#{name})" do
      repo = Puppet::Util::RepoUtils.repoutil(name)
      it "should not return nil" do
        repo.should_not be_nil
      end
      if not repo.nil?
        it "should return a subclass of Puppet::Util::RepoUtil" do
          repo.class.equal? Class
          (repo < Puppet::Util::RepoUtil).should be_true
        end
        [ [ :package_name_regexp, lambda { repo.package_name_regexp } ],
          [ :package_prefix_regexp, lambda { repo.package_prefix_regexp } ],
          [ :validate_package_name, lambda { repo.validate_package_name('xyz') } ],
          [ :validate_package_prefix, lambda { repo.validate_package_prefix('xyz') } ],
          [ :package_name_to_pattern, lambda { repo.package_name_to_pattern('xyz') } ],
          [ :package_prefix_to_pattern, lambda { repo.package_prefix_to_pattern('xyz') } ],
          [ :candidates_cache, lambda { repo.candidates_cache } ],
          [ :records_cache, lambda { repo.records_cache } ],
          [ :clear_candidates_cache, lambda { repo.clear_candidates_cache } ],
          [ :clear_records_cache, lambda { repo.clear_records_cache } ],
          [ :retrieve_candidates, lambda { repo.retrieve_candidates('xyz') } ],
          [ :retrieve_records, lambda { repo.retrieve_records('xyz') } ],
          [ :package_records, lambda { repo.package_records('xyz') } ],
          [ :package_versions, lambda { repo.package_versions('xyz') } ],
          [ :packages_with_prefix, lambda { repo.packages_with_prefix('xyz') } ],
          [ :package_versions_with_prefix, lambda { repo.package_versions_with_prefix('xyz') } ],
          [ :package_candidates_with_prefix, lambda { repo.package_candidates_with_prefix('xyz') } ],
          [ :package_records_with_prefix, lambda { repo.package_records_with_prefix('xyz') } ],
        ].each do |name, method|
          context "#{name}" do
            it "should be implemented and raise only allowed exceptions" do
              # expect {method}.not_to raise_error(ParticularErrorClass) is now
              # deprecated
              begin
                method.call
              rescue NotImplementedError
                fail "#{repo}.#{name} is not implemented"
              rescue ArgumentError, Puppet::ExecutionFailure, Puppet::Error
                # pass
              end
            end
          end
        end
      end
    end
  end

end
