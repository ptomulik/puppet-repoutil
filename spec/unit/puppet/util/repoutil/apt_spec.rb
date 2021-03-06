require 'spec_helper'
require 'puppet/util/repoutil'

begin
  require 'zlib'
rescue LoadError
  have_zlib = false
else
  have_zlib = true
end

describe "Puppet::Util.repoutil(:apt)" do
  it "should exist" do
    expect(Puppet::Util::RepoUtils.repoutil(:apt)).to_not be_nil
  end

  repo = Puppet::Util::RepoUtils.repoutil(:apt)

  context "package_name_regexp" do
    re = repo.package_name_regexp
    [ '00', '0a', 'a0', 'aa',
      '0.', 'a.', '0+', 'a+', '0-', 'a-',
      'apache2', 'addres.freamework', 'anjuta-dbg'
    ].each do |str|
      it "should match '#{str}'" do
        expect(str.match(/^#{re}$/)).to_not be_nil
      end
    end
    [ '', ' ', '  ',
      '0', 'a', 'A',

      '0A', 'aA', 'AA',

      '-a', '+a', '_a', '.a',

      'ab_cd',

      'ab cd', 'ab_cd', 'ab`cd', 'ab!cd', 'ab@cd', 'ab#cd', 'ab$cd', 'ab%cd',
      'ab^cd', 'ab&cd', 'ab*cd', 'ab(cd', 'ab)cd', 'ab)cd', 'ab{cd', 'ab}cd',
      'ab[cd', 'ab]cd', 'ab:cd', 'ab;cd', 'ab"cd', 'ab\'cd', 'ab|cd','ab\\cd',
      'ab<cd', 'ab,cd', 'ab>cd', 'ab?cd', 'ab/cd',

    ].each do |str|
      it "should not match '#{str}'" do
        expect(str.match(/^#{re}$/)).to be_nil
      end
    end
  end

  context "package_prefix_regexp" do
    re = repo.package_prefix_regexp
    [ '', '0', 'a',
      '00', '0a', 'a0', 'aa',
      '0.', 'a.', '0+', 'a+', '0-', 'a-',
      'apt', 'p4', 'apache2'
    ].each do |str|
      it "should match '#{str}'" do
        expect(str.match(/^#{re}$/)).to_not be_nil
      end
    end

    [ ' ', '  ',
      'A',
      '0A', 'aA', 'AA',

      '-a', '+a', '_a', '.a',

      'ab cd', 'ab_cd', 'ab`cd', 'ab!cd', 'ab@cd', 'ab#cd', 'ab$cd', 'ab%cd',
      'ab^cd', 'ab&cd', 'ab*cd', 'ab(cd', 'ab)cd', 'ab)cd', 'ab{cd', 'ab}cd',
      'ab[cd', 'ab]cd', 'ab:cd', 'ab;cd', 'ab"cd', 'ab\'cd', 'ab|cd','ab\\cd',
      'ab<cd', 'ab,cd', 'ab>cd', 'ab?cd', 'ab/cd',
    ].each do |str|
      it "should not match '#{str}'" do
        expect(str.match(/^#{re}$/)).to be_nil
      end
    end
  end

  context "escape_package_name" do
    {
      '0123456789' => '0123456789',
      'abcdefghijklmnopqrstuvwxyz' => 'abcdefghijklmnopqrstuvwxyz',
      '~!@#$%^&*())-=_{}[]:;\'"|' => '~!@#$%^&*())-=_{}[]:;\'"|',
      '.+' => '\\.\\+'
    }.each do |unescaped,escaped|
      it "should map #{unescaped.inspect} to #{escaped.inspect}" do
        expect(repo.escape_package_name(unescaped)).to eq(escaped)
      end
    end
  end

  context "escape_package_prefix" do
    {
      '0123456789' => '0123456789',
      'abcdefghijklmnopqrstuvwxyz' => 'abcdefghijklmnopqrstuvwxyz',
      '~!@#$%^&*())-=_{}[]:;\'"|' => '~!@#$%^&*())-=_{}[]:;\'"|',
      '.+' => '\\.\\+'
    }.each do |unescaped,escaped|
      it "should map #{unescaped.inspect} to #{escaped.inspect}" do
        expect(repo.escape_package_prefix(unescaped)).to eq(escaped)
      end
    end
  end

  context "retrieve_candidates" do
    context "when execution error 'No packages found' occurs" do
      before(:each) do
        repo.stubs(:show_policies).with('^foobar').raises(Puppet::ExecutionFailure, "No packages found")
      end
      it "should return empty hash" do
        expect(repo.retrieve_candidates('^foobar')).to eql({})
      end
    end
    context "when execution error occurs" do
      before(:each) do
        repo.stubs(:show_policies).with('^foobar').raises(Puppet::ExecutionFailure, "Blah blah blah")
      end
      it "should return empty hash" do
        expect { repo.retrieve_candidates('^foobar') }.to raise_error(Puppet::ExecutionFailure, "Blah blah blah")
      end
    end
  end

  context "using fixture files apt-cache-*.txt.gz" do
    dir = File.join(File.dirname(__FILE__),'..','..','..','..','fixtures','modules', 'repoutil-fixtures','files')
    repo = Puppet::Util::RepoUtils.repoutil(:apt)
    Zlib::GzipReader.open(File.join(dir, "apt-cache-show.txt.gz")) { |gz|
      repo.stubs(:aptcache).with('-q=2', '-a', 'show', '^').returns(gz.read)
    }
    Zlib::GzipReader.open(File.join(dir, "apt-cache-policy.txt.gz")) { |gz|
      repo.stubs(:aptcache).with('-q=2', '-a', 'policy', '^').returns(gz.read)
    }
    repo.stubs(:aptcache).with('-q=2', '-a', 'show', '^nonexistent').returns("\n")
    repo.stubs(:aptcache).with('-q=2', '-a', 'policy', '^nonexistent').returns("\n")

    context "retrieve_records('^')" do
      records = repo.retrieve_records('^')
      it "should return a nonempty hash" do
        expect(records).to be_a(Hash)
        expect(records).to_not be_empty
      end
      it "should update records_cache" do
      end
    end

    context "retrieve_candidates('^')" do
      candidates = repo.retrieve_candidates('^')
      it "should return a nonempty hash" do
        expect(candidates).to be_a(Hash)
        expect(candidates).to_not be_empty
      end
      it "should update candidates_cache" do
        # TODO: implement the test
      end
    end

    context "retrieve_records('^nonexistent')" do
      records = repo.retrieve_records('^nonexistent')
      it "should return an empty hash" do
        expect(records).to be_a(Hash)
        expect(records).to be_empty
      end
    end

    context "retrieve_candidates('^nonexistent')" do
      candidates = repo.retrieve_candidates('^nonexistent')
      it "should return an empty hash" do
        expect(candidates).to be_a(Hash)
        expect(candidates).to be_empty
      end
    end

  end
end
