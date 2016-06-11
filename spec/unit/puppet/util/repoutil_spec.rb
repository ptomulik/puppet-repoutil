require 'spec_helper'
require 'puppet/util/repoutil'

def ruby18?
  RUBY_VERSION =~ /^1\.8\./
end

describe Puppet::Util do
  describe 'newrepoutil' do
    let(:block) { Proc.new {} }
    it 'should just call Puppet::Util::Repoutils.newrepoutil' do
      Puppet::Util::RepoUtils.expects(:newrepoutil).once.with(:foo,:bar).returns(:ok)
      expect(described_class.newrepoutil(:foo,:bar,&block)).to equal(:ok)
    end
  end
  describe 'repoutil' do
    let(:block) { Proc.new {} }
    it 'should just call Puppet::Util::Repoutils.repoutil' do
      Puppet::Util::RepoUtils.expects(:repoutil).once.with(:foo).returns(:ok)
      expect(described_class.repoutil(:foo)).to equal(:ok)
    end
  end
  describe 'repoutils' do
    let(:block) { Proc.new {} }
    it 'should just call Puppet::Util::Repoutils.repoutils' do
      Puppet::Util::RepoUtils.expects(:repoutils).once.with().returns(:ok)
      expect(described_class.repoutils).to equal(:ok)
    end
  end
  describe 'suitablerepoutils' do
    let(:block) { Proc.new {} }
    it 'should just call Puppet::Util::Repoutils.suitablerepoutils' do
      Puppet::Util::RepoUtils.expects(:suitablerepoutils).once.with().returns(:ok)
      expect(described_class.suitablerepoutils).to equal(:ok)
    end
  end
  describe 'defaultrepoutil' do
    let(:block) { Proc.new {} }
    it 'should just call Puppet::Util::Repoutils.defaultrepoutil' do
      Puppet::Util::RepoUtils.expects(:defaultrepoutil).once.with().returns(:ok)
      expect(described_class.defaultrepoutil).to equal(:ok)
    end
  end
end

describe Puppet::Util::RepoUtils do
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
      expect(described_class.respond_to?(method)).to eql(true)
    end
  end

  describe 'newrepoutil' do
    context 'when called with non-hash options' do
      it 'raises ArgumentError' do
        expect { described_class.newrepoutil(:foo, 'A') }.to \
          raise_error(ArgumentError, "second argument must be a hash, not #{'A'.inspect}")
      end
    end
    context 'when unrepoutil(:foo) returns true' do
      before(:each) do
        described_class.stubs(:unrepoutil).with(:foo).returns(true)
        Puppet::Util::ClassGen.stubs(:genclass)
      end

      it 'invokes Puppet.debug' do
        Puppet.expects(:debug).once.with("Reloading foo #{described_class.name} repoutil")
        described_class.newrepoutil(:foo)
      end
    end
    context 'when invoked without :parent' do
      let(:parent) { Class.new {} }
      let(:attributes) {  Hash[ :resource_type => Puppet::Util::RepoUtil ] }
      it 'uses the :parent class as an argument to genclass()' do
        described_class.expects(:genclass).
          once.with(:foo, { :parent => Puppet::Util::RepoUtil,
                            :overwrite => true,
                            :hash => described_class.class_eval { class_variable_get(:@@repoutil_hash) },
                            :attributes => attributes })
        described_class.newrepoutil(:foo)
      end
    end
    context 'when invoked with :parent being a Class' do
      let(:parent) { Class.new {} }
      let(:attributes) {  Hash[ :resource_type => Puppet::Util::RepoUtil ] }
      it 'uses the :parent class as an argument to genclass()' do
        described_class.expects(:genclass).
          once.with(:foo, { :parent => parent,
                            :overwrite => true,
                            :hash => described_class.class_eval { class_variable_get(:@@repoutil_hash) },
                            :attributes => attributes })
        described_class.newrepoutil(:foo, :parent => parent)
      end
    end
    context 'when invoked with :parent being a name of a known class' do
      let(:parent) { Class.new {} }
      let(:attributes) {  Hash[ :resource_type => Puppet::Util::RepoUtil ] }
      before(:each) { described_class.stubs(:repoutil).with('Parent').returns(parent) }
      it 'uses the :parent class as an argument to genclass()' do
        described_class.expects(:genclass).
          once.with(:foo, { :parent => parent,
                            :overwrite => true,
                            :hash => described_class.class_eval { class_variable_get(:@@repoutil_hash) },
                            :attributes => attributes })
        described_class.newrepoutil(:foo, :parent => 'Parent')
      end
    end
    context 'when invoked with :parent being a String (not a known class name)' do
      let(:parent) { Class.new {} }
      let(:attributes) {  Hash[ :resource_type => Puppet::Util::RepoUtil ] }
      before(:each) { described_class.stubs(:repoutil).returns(nil) }
      it 'uses the :parent class as an argument to genclass()' do
        expect { described_class.newrepoutil(:foo, :parent => 'blabla') }.to \
          raise_error(Puppet::DevError, "Could not find parent repoutil blabla of foo")
      end
    end
  end

  describe 'unrepoutil' do
    context 'with name=:foo' do
      before(:each) do
        described_class.expects(:rmclass).
          once.with(:foo, :hash => described_class.class_eval { class_variable_get(:@@repoutil_hash) })
      end
      it 'invokes rmclass(:foo, :hash => @@repoutil_hash)' do
        described_class.unrepoutil(:foo)
      end
      it 'sets @defaultrepoutil=nil if @defaultrepoutil.name == :foo' do
        described_class.instance_variable_set(:@defaultrepoutil, Class.new { def self.name; :foo; end })
        described_class.unrepoutil(:foo)
        expect(described_class.instance_variable_get(:@defaultrepoutil)).to be_nil
      end
    end
  end

  describe 'repoutil' do
    let(:loader) { Class.new { def self.load(name, env); true; end } }
    let(:foo) { Class.new }
    before(:each) do
      hash = {:foo => foo}
      described_class.class_eval { class_variable_set(:@@repoutil_hash, hash) }
      Puppet::Node::Environment.stubs(:current).returns(:CE1)
      Puppet.stubs(:lookup).with(:current_environment).returns(:CE2)
      described_class.stubs(:repoutilloader).returns(loader)
    end
    it 'returns @@repoutil_hash[name] in first place' do
      loader.expects(:load).never
      expect(described_class.repoutil(:foo)).to equal(foo)
    end
    it 'uses repoutilloader.load(name, Puppet::Node::Environment.current) on puppet 3.4.7' do
      # also verifies that the input name gets lowercased and interned
      Puppet.stubs(:version).returns('3.4.7')
      loader.expects(:load).once.with(:foo, :CE1).returns(false)
      expect(described_class.repoutil('Foo')).to equal(foo)
    end
    it 'uses repoutilloader.load(name, Puppet.lookup(:current_environment)) on puppet 3.5.0' do
      # also verifies that the input name gets lowercased and interned
      Puppet.stubs(:version).returns('3.5.0')
      loader.expects(:load).once.with(:foo, :CE2).returns(false)
      expect(described_class.repoutil('Foo')).to equal(foo)
    end
  end

  describe 'repoutils' do
    context 'when @@repoutil_hash is empty' do
      before(:each) do
        described_class.class_eval { class_variable_set(:@@repoutil_hash, {}) }
      end
      it 'invokes loadall' do
        described_class.expects(:loadall).once.with()
        expect(described_class.repoutils).to match_array([])
      end
    end
    context 'when @@repoutil_hash is not empty' do
      before(:each) do
        described_class.class_eval { class_variable_set(:@@repoutil_hash, {:foo => :RU1, :bar => :RU2}) }
      end
      it 'does not call loadall' do
        described_class.expects(:loadall).never
        described_class.repoutils
      end
      it 'returns keys from @@repoutil_hash' do
        expect(described_class.repoutils).to match_array([:foo, :bar])
      end
    end
  end

  describe 'suitablerepoutils' do
    context 'when @@repoutil_hash is empty' do
      before(:each) do
        described_class.class_eval { class_variable_set(:@@repoutil_hash, {}) }
      end
      it 'invokes loadall' do
        described_class.expects(:loadall).once.with()
        expect(described_class.suitablerepoutils).to match_array([])
      end
    end
    context 'when @@repoutil_hash is not empty' do
      let(:foo)   { Class.new { def self.suitable?; true; end } }
      let(:bar)   { Class.new { def self.suitable?; false; end } }
      let(:geez)  { Class.new { def self.suitable?; true; end } }
      before(:each) do
        hash = {:foo => foo, :bar => bar, :geez => geez}
        described_class.class_eval { class_variable_set(:@@repoutil_hash, hash) }
      end
      it 'does not call loadall' do
        described_class.expects(:loadall).never
        described_class.suitablerepoutils
      end
      it 'returns keys from @@repoutil_hash' do
        expect(described_class.suitablerepoutils).to match_array([foo, geez])
      end
    end
  end

  describe 'defaultrepoutil' do
    context 'when @defaultrepoutil is set' do
      let(:util) { Class.new }
      before(:each) do
        described_class.instance_variable_set(:@defaultrepoutil, util)
      end
      it 'just returns @defaultrepoutil' do
        described_class.expects(:suitablerepoutil).never
        expect(described_class.defaultrepoutil).to equal(util)
      end
    end
    context 'when @defaultrepoutil is not set' do
      before(:each) do
        described_class.instance_variable_set(:@defaultrepoutil, nil)
      end
      context 'and there are default suitable repoutils with different specificities' do
        let(:foo)   { Class.new { def self.default?; false; end } }
        let(:bar)   { Class.new { def self.default?; true; end ; def self.specificity; 2; end } }
        let(:geez)  { Class.new { def self.default?; true; end ; def self.specificity; 1; end } }
        before(:each) do
          described_class.expects(:suitablerepoutils).once.with.returns([foo, bar, geez])
        end
        it 'returns that of suitablerepoutils which has max specificity' do
          expect(described_class.defaultrepoutil).to equal(bar)
          expect(described_class.instance_variable_get(:@defaultrepoutil)).to equal(bar)
        end
      end
      context 'and there are default suitable repoutils with same specificity' do
        let(:foo)   { Class.new { def self.default?; false; end } }
        let(:bar)   { Class.new { def self.default?; true;  end;
                                  def self.specificity; 2;  end;
                                  def self.name; :bar;      end } }
        let(:geez)  { Class.new { def self.default?; true;  end;
                                  def self.specificity; 2;  end;
                                  def self.name; :geez;     end } }
        before(:each) do
          described_class.expects(:suitablerepoutils).once.with.returns([foo, bar, geez])
        end
        it 'displays warning and returns the first repoutil found' do
          Puppet.expects(:warning).
            once.with("Found multiple default repoutils for #{described_class.name}: bar, geez; using bar")
          expect(described_class.defaultrepoutil).to equal(bar)
          expect(described_class.instance_variable_get(:@defaultrepoutil)).to equal(bar)
        end
      end
    end
  end

  describe 'loadall' do
    let(:loader)  { Class.new { def self.loadall; :all; end } }
    before(:each) { described_class.expects(:repoutilloader).once.with().returns(loader) }
    it 'just invokes repoutilloader.loadall' do
      expect(described_class.loadall).to equal(:all)
    end
  end

  describe 'repoutilloader' do
    context 'if @@repoutilloader is set' do
      let(:loader)  { Class.new }
      before(:each) { l = loader; described_class.class_eval { class_variable_set(:@@repoutilloader, l) } }
      it 'it just returns @@repoutilloader' do
        expect(described_class.repoutilloader).to equal(loader)
      end
    end
    context 'if @@repoutilloader is undefined' do
      let(:loader)  { Class.new }
      before(:each) { described_class.class_eval { remove_class_variable(:@@repoutilloader) } }
      context 'on puppet 3.7.0' do
        before(:each) do
          Puppet.stubs(:version).returns('3.7.0')
          Puppet::Util::Autoload.expects(:new).once.
            with(described_class, 'puppet/util/repoutil', { :wrap => false }).returns(loader)
        end
        it 'returns loader created by Puppet::Util::Autoload' do
          expect(described_class.repoutilloader).to equal(loader)
        end
      end
      context 'on puppet 4.0.0' do
        before(:each) do
          Puppet.stubs(:version).returns('4.0.0')
          Puppet::Util::Autoload.expects(:new).once.
            with(described_class, 'puppet/util/repoutil', {}).returns(loader)
        end
        it 'returns loader created by Puppet::Util::Autoload' do
          expect(described_class.repoutilloader).to equal(loader)
        end
      end
    end
  end

  describe 'collective_query' do
    context 'with utils=[]' do
      it 'should return an empty hash' do
        expect(described_class.collective_query(:opname, :subject, [])).to eql({})
      end
    end
    context 'with custom utils' do
      let(:util1) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util1; end
          def self.package_versions(package)
            case package
            when 'apache'; return ['2.2', '2.4' ];
            when 'bash';   return ['4.3-11', '4.3-14' ]
            end
          end
        end
      end
      let(:util2) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util2; end
          def self.package_versions(package)
            case package
            when 'apache';    return [ '2.4', '2.6' ]
            when 'alsa-base'; return [ '1.0.27+1' ]
            end
          end
        end
      end
      let(:util3) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util3; end
          def self.package_versions(package)
            case package
            when 'bash';    return [ '4.3-12' ]
            end
          end
        end
      end
      before(:each) do
        described_class.stubs(:repoutil).with(:util1).returns(util1)
        described_class.stubs(:repoutil).with(:util2).returns(util2)
        described_class.stubs(:repoutil).with(:util3).returns(util3)
      end
      it 'returns results collected from particular utils' do
        packages = ['apache', 'bash', 'alsa-base', 'foo']
        utils    = [util1, :util2, 'util3']
        expect(described_class.collective_query(:package_versions, packages, utils)).to eql({
          :util1 => { 'apache' => ['2.2', '2.4'], 'bash' => [ '4.3-11', '4.3-14' ] },
          :util2 => { 'apache' => ['2.4', '2.6'], 'alsa-base' => ['1.0.27+1'] },
          :util3 => { 'bash'   => ['4.3-12'] }
        })
      end
    end
  end

  describe 'collective_search_hash' do
    context 'with utils=[]' do
      it 'should return an empty hash' do
        expect(described_class.collective_query(:opname, :subject, [])).to eql({})
      end
    end
    context 'with custom utils' do
      let(:util1) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util1; end
          def self.package_versions_with_prefix(package)
            case package
            when 'apache'; return { 'apache22' => ['2.2.14' ], 'apache24' => ['2.4.28'] }
            when 'bash';   return { 'bash' => ['4.3-11', '4.3-14' ] }
            else return {}
            end
          end
        end
      end
      let(:util2) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util2; end
          def self.package_versions_with_prefix(package)
            case package
            when 'apache';    return { 'apache' => [ '2.4', '2.6' ] }
            when 'alsa-base'; return { 'alsa-base' => [ '1.0.27+1' ] }
            else return {}
            end
          end
        end
      end
      let(:util3) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util3; end
          def self.package_versions_with_prefix(package)
            case package
            when 'bash';    return { 'bash' => [ '4.3-12' ] }
            else return {}
            end
          end
        end
      end
      before(:each) do
        described_class.stubs(:repoutil).with(:util1).returns(util1)
        described_class.stubs(:repoutil).with(:util2).returns(util2)
        described_class.stubs(:repoutil).with(:util3).returns(util3)
      end
      it 'returns results collected from particular utils' do
        packages = ['apache', 'bash', 'alsa-base', 'foo']
        utils    = [util1, :util2, 'util3']
        expect(described_class.collective_search_hash(:package_versions_with_prefix, packages, utils)).to eql({
          :util1 => { 'apache22' => ['2.2.14'], 'apache24' => ['2.4.28'], 'bash' => [ '4.3-11', '4.3-14' ] },
          :util2 => { 'apache' => ['2.4', '2.6'], 'alsa-base' => ['1.0.27+1'] },
          :util3 => { 'bash'   => ['4.3-12'] }
        })
      end
    end
  end

  describe 'collective_search_array' do
    context 'with utils=[]' do
      it 'should return an empty hash' do
        expect(described_class.collective_query(:opname, :subject, [])).to eql({})
      end
    end
    context 'with custom utils' do
      let(:util1) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util1; end
          def self.packages_with_prefix(package)
            case package
            when 'apache'; return [ 'apache22', 'apache24' ]
            when 'bash';   return [ 'bash' ]
            else return []
            end
          end
        end
      end
      let(:util2) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util2; end
          def self.packages_with_prefix(package)
            case package
            when 'apache';    return [ 'apache' ]
            when 'alsa-base'; return [ 'alsa-base' ]
            else return []
            end
          end
        end
      end
      let(:util3) do
        Class.new(Puppet::Util::RepoUtil) do
          def self.name; :util3; end
          def self.packages_with_prefix(package)
            case package
            when 'bash';    return [ 'bash' ]
            else return []
            end
          end
        end
      end
      before(:each) do
        described_class.stubs(:repoutil).with(:util1).returns(util1)
        described_class.stubs(:repoutil).with(:util2).returns(util2)
        described_class.stubs(:repoutil).with(:util3).returns(util3)
      end
      it 'returns results collected from particular utils' do
        packages = ['apache', 'bash', 'alsa-base', 'foo']
        utils    = [util1, :util2, 'util3']
        expect(described_class.collective_search_array(:packages_with_prefix, packages, utils)).to eql({
          :util1 => [ 'apache22', 'apache24', 'bash' ],
          :util2 => [ 'apache', 'alsa-base' ],
          :util3 => [ 'bash' ]
        })
      end
    end
  end

  [ :package_records,
    :package_versions,
    :package_candidates ].each do |m|
    describe "#{m}" do
      context 'with default utils' do
        let(:utils)   { [ Class.new ] }
        before(:each) { described_class.stubs(:suitablerepoutils).returns(utils) }
        it "just invokes collective_query(#{m.inspect}, arg, suitableutils)" do
          described_class.expects(:collective_query).once.with(m, :arg, utils).returns(:ok)
          expect(described_class.method(m).call(:arg)).to equal(:ok)
        end
      end
      context 'with non-default utils' do
        it "just invokes collective_query(#{m.inspect}, arg, utils)" do
          described_class.expects(:collective_query).once.with(m, :arg, :utils).returns(:ok)
          expect(described_class.method(m).call(:arg, :utils)).to equal(:ok)
        end
      end
    end
  end

  {
    :packages_with_prefixes => :packages_with_prefix
  }.each do |m,n|
    describe "#{m}" do
      context 'with default utils' do
        let(:utils)   { [ Class.new ] }
        before(:each) { described_class.stubs(:suitablerepoutils).returns(utils) }
        it "just invokes collective_query(#{m.inspect}, arg, suitableutils)" do
          described_class.expects(:collective_search_array).once.with(n, :arg, utils).returns(:ok)
          expect(described_class.method(m).call(:arg)).to equal(:ok)
        end
      end
      context 'with non-default utils' do
        it "just invokes collective_query(#{m.inspect}, arg, utils)" do
          described_class.expects(:collective_search_array).once.with(n, :arg, :utils).returns(:ok)
          expect(described_class.method(m).call(:arg, :utils)).to equal(:ok)
        end
      end
    end
  end

  {
    :package_records_with_prefixes => :package_records_with_prefix,
    :package_versions_with_prefixes => :package_versions_with_prefix,
    :package_candidates_with_prefixes => :package_candidates_with_prefix
  }.each do |m,n|
    describe "#{m}" do
      context 'with default utils' do
        let(:utils)   { [ Class.new ] }
        before(:each) { described_class.stubs(:suitablerepoutils).returns(utils) }
        it "just invokes collective_query(#{m.inspect}, arg, suitableutils)" do
          described_class.expects(:collective_search_hash).once.with(n, :arg, utils).returns(:ok)
          expect(described_class.method(m).call(:arg)).to equal(:ok)
        end
      end
      context 'with non-default utils' do
        it "just invokes collective_query(#{m.inspect}, arg, utils)" do
          described_class.expects(:collective_search_hash).once.with(n, :arg, :utils).returns(:ok)
          expect(described_class.method(m).call(:arg, :utils)).to equal(:ok)
        end
      end
    end
  end
end

describe Puppet::Util::RepoUtil do

  utils = [
    :apt,
    :aptitude,
    :ports,
  ]

  it "should be a class derived from Puppet::Provider" do
    expect(described_class < Puppet::Provider).to be_truthy
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
      expect(described_class.respond_to?(method)).to eql(true)
    end
  end

  { :package_name_regexp => lambda { described_class.package_name_regexp },
    :package_prefix_regexp => lambda { described_class.package_prefix_regexp },
    :package_name_to_pattern => lambda { described_class.package_name_to_pattern('foo') },
    :package_prefix_to_pattern => lambda { described_class.package_prefix_to_pattern('foo') },
    :retrieve_candidates => lambda { described_class.retrieve_candidates('foo') },
    :retrieve_records => lambda { described_class.retrieve_records('foo') },
  }.each do |name, method|
    it "#{name}('') should raise NotImplementedError" do
      expect(method).to raise_error(NotImplementedError)
    end
  end

  utils.each do |name|

    context "repoutil(:#{name})" do
      repo = Puppet::Util::RepoUtils.repoutil(name)
      it "should not return nil" do
        expect(repo).to_not be_nil
      end
      if not repo.nil?
        it "should return a subclass of #{described_class}" do
          repo.class.equal? Class
          expect(repo < described_class).to be_truthy
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

  describe 'validate_package_name' do
    before(:each) do
      described_class.stubs(:package_name_regexp).returns(/[_a-zA-Z]\w+/)
    end
    it 'does not raise for a valid package name' do
      expect { described_class.validate_package_name('_CuCumBer78') }.to_not raise_error
    end
    it 'raises ArgumentError for an invalid package name' do
      expect { described_class.validate_package_name('Inv@l!D') }.to raise_error(ArgumentError, "ill-formed package name 'Inv@l!D'")
    end
  end

  describe 'validate_package_prefix' do
    before(:each) do
      described_class.stubs(:package_prefix_regexp).returns(/[_a-zA-Z]\w+/)
    end
    it 'does not raise for a valid package prefix' do
      expect { described_class.validate_package_prefix('_CuCum') }.to_not raise_error
    end
    it 'raises ArgumentError for an invalid package prefix' do
      expect { described_class.validate_package_prefix('Inv@') }.to raise_error(ArgumentError, "ill-formed package name prefix 'Inv@'")
    end
  end

  describe 'candidates_cache' do
    let(:klass) do
      Class.new(described_class) {}
    end
    it 'initially returns empty hash' do
      expect(klass.candidates_cache).to eql({})
    end
    it 'should return same instance if unchanged' do
      expect(klass.candidates_cache).to equal(klass.candidates_cache)
      klass.candidates_cache['foo'] = 'bar'
      expect(klass.candidates_cache).to equal(klass.candidates_cache)
    end
  end

  describe 'records_cache' do
    let(:klass) do
      Class.new(described_class) {}
    end
    it 'initially returns empty hash' do
      expect(klass.records_cache).to eql({})
    end
    it 'should return same instance if unchanged' do
      expect(klass.records_cache).to equal(klass.records_cache)
      klass.records_cache['foo'] = 'bar'
      expect(klass.records_cache).to equal(klass.records_cache)
    end
  end

  describe 'package_records' do
    let (:klass) do
      Class.new(described_class) do
        def self.package_name_regexp; /[_a-zA-Z]\w+/; end
        def self.package_name_to_pattern(package); "^#{package}$"; end
        def self.retrieve_records(pattern)
          records = {}
          if pattern == '^_asdf21$'
            records['_asdf21'] = "retrieved records"
          end
          records_cache.merge!(records)
          records
        end
      end
    end
    it 'retrieves version from #records_cache in first place' do
      klass.records_cache['_asdf21'] = 'cached records'
      expect(klass.package_records('_asdf21')).to eq('cached records')
    end
    it 'retrieves version from #retrieve_records if not in records_cache' do
      expect(klass.package_records('_asdf21')).to eq('retrieved records')
      expect(klass.records_cache['_asdf21']).to eql('retrieved records')
    end
  end

  describe 'package_versions' do
    let (:klass) do
      Class.new(described_class) do
        def self.package_name_regexp; /[_a-zA-Z]\w+/; end
        def self.package_name_to_pattern(package); "^#{package}$"; end
        def self.retrieve_records(pattern)
          records = {}
          if pattern == '^_asdf21$'
            records['_asdf21'] = {'1.2.3' => 'retrieved one', '2.3.4' => 'retrieved two'}
          end
          records_cache.merge!(records)
          records
        end
      end
    end
    it 'retrieves versions from records_cache in first place' do
      klass.records_cache['_asdf21'] = {'1.1.1' => 'cached one', '2.2.2' => 'cached two'}
      expect(klass.package_versions('_asdf21')).to match_array(['1.1.1', '2.2.2'])
    end
    it 'retrieves versions from retrieve_records if not in records_cache' do
      expect(klass.package_versions('_asdf21')).to match_array(['1.2.3', '2.3.4'])
      expect(klass.records_cache['_asdf21'].keys).to match_array(['1.2.3', '2.3.4'])
    end
  end

  describe 'package_candidate' do
    let (:klass) do
      Class.new(described_class) do
        def self.package_name_regexp; /[_a-zA-Z]\w+/; end
        def self.package_name_to_pattern(package); "^#{package}$"; end
        def self.retrieve_candidates(pattern)
          candidates = {}
          if pattern == '^_asdf21$'
            candidates['_asdf21'] = '3.4.5'
          end
          candidates_cache.merge!(candidates)
          candidates
        end
      end
    end
    it 'retrieves version from #candidates_cache in first place' do
      klass.candidates_cache['_asdf21'] = '2.3.4'
      expect(klass.package_candidate('_asdf21')).to eq('2.3.4')
    end
    it 'retrieves version from #retrieve_candidates if not in candidates_cache' do
      expect(klass.package_candidate('_asdf21')).to eq('3.4.5')
      expect(klass.candidates_cache['_asdf21']).to eq('3.4.5')
    end
  end

  describe 'packages_with_prefix', :if => !ruby18? do
    before(:each) do
      # NOTE: on 1.8.x, this breaks some later tests, so it's disabled (above)
      # see https://github.com/freerange/mocha/issues/99
      described_class.stubs(:package_candidates_with_prefix).with('abc123').returns(
        {'abc12345' => {'1.2.3' => 'A', '2.3.4' => 'B' },
         'abc123XZ' => {'1.2.3' => 'C', '2.3.4' => 'D' } })
    end
    it 'returns package names' do
      expect(described_class.packages_with_prefix('abc123')).to match_array(['abc12345', 'abc123XZ'])
    end
  end

  describe 'package_versions_with_prefix' do
    let(:klass) do
      Class.new(described_class) do
        def self.package_prefix_regexp; /[_a-zA-Z]\w+/; end
        def self.package_prefix_to_pattern(prefix); "^#{prefix}"; end
        def self.retrieve_records(pattern)
          records = {}
          if pattern == '^abc123' then
            records['abc12345'] = {'1.2.3' => 'A', '2.3.4' => 'B' }
            records['abc123XZ'] = {'3.4.5' => 'C', '4.5.6' => 'D' }
          end
          records_cache.merge!(records)
          records
        end
      end
    end
    it 'returns versions of packages found' do
      expect(klass.package_versions_with_prefix('abc123').keys).to match_array(['abc12345', 'abc123XZ'])
      expect(klass.package_versions_with_prefix('abc123')['abc12345']).to match_array(['1.2.3', '2.3.4'])
      expect(klass.package_versions_with_prefix('abc123')['abc123XZ']).to match_array(['3.4.5', '4.5.6'])
    end
  end

  describe 'package_candidates_with_prefix' do
    let(:klass) do
      Class.new(described_class) do
        def self.package_prefix_regexp; /[_a-zA-Z]\w+/; end
        def self.package_prefix_to_pattern(prefix); "^#{prefix}"; end
        def self.retrieve_candidates(pattern)
          candidates = {}
          if pattern == '^abc123' then
            candidates['abc12345'] = '2.3.4'
            candidates['abc123XZ'] = '4.5.6'
          end
          candidates_cache.merge!(candidates)
          candidates
        end
      end
    end
    it 'returns package candidates' do
      expect(klass.package_candidates_with_prefix('abc123').keys).to match_array(['abc12345', 'abc123XZ'])
      expect(klass.package_candidates_with_prefix('abc123')['abc12345']).to eql('2.3.4')
      expect(klass.package_candidates_with_prefix('abc123')['abc123XZ']).to eql('4.5.6')
    end
  end

  describe 'package_records_with_prefix' do
    let(:klass) do
      Class.new(described_class) do
        def self.package_prefix_regexp; /[_a-zA-Z]\w+/; end
        def self.package_prefix_to_pattern(prefix); "^#{prefix}"; end
        def self.retrieve_records(pattern)
          records = {}
          if pattern == '^abc123' then
            records['abc12345'] = { '1.2.3' => 'A', '2.3.4' => 'B' }
            records['abc123XZ'] = { '3.4.5' => 'C', '4.5.6' => 'D' }
          end
          records_cache.merge!(records)
          records
        end
      end
    end
    it 'returns package records' do
      expect(klass.package_records_with_prefix('abc123').keys).to match_array(['abc12345', 'abc123XZ'])
      expect(klass.package_records_with_prefix('abc123')['abc12345']).to eql({'1.2.3' => 'A', '2.3.4' => 'B'})
      expect(klass.package_records_with_prefix('abc123')['abc123XZ']).to eql({'3.4.5' => 'C', '4.5.6' => 'D'})
    end
  end
end
