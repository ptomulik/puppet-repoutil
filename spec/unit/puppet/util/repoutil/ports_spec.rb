require 'spec_helper'
require 'puppet/util/repoutil'

begin
  require 'zlib'
rescue LoadError
  have_zlib = false
else
  have_zlib = true
end

describe "Puppet::Util.repoutil(:ports)" do
  it "should exist" do
    expect(Puppet::Util::RepoUtils.repoutil(:ports)).to_not be_nil
  end

  repo = Puppet::Util::RepoUtils.repoutil(:ports)

  context "package_name_regexp" do
    re = repo.package_name_regexp
    [ '0', 'a', 'A',
      '0_', 'a_', 'A_', '0.', 'a.', 'A.', '0+', 'a+', 'A+', '0-', 'a-', 'A-',
      'a0', 'aa', 'aA', 'A0', 'Aa', 'AA',
      'apache22', 'jack_mixer', 'last.fm'
    ].each do |str|
      it "should match '#{str}'" do
        expect(str.match(/^#{re}$/)).to_not be_nil
      end
    end
    [ '', ' ', '  ',

      'ab cd', 'ab`cd', 'ab!cd', 'ab@cd', 'ab#cd', 'ab$cd', 'ab%cd', 'ab^cd',
      'ab&cd', 'ab*cd', 'ab(cd', 'ab)cd', 'ab)cd', 'ab{cd', 'ab}cd', 'ab[cd',
      'ab]cd', 'ab:cd', 'ab;cd', 'ab"cd', 'ab\'cd', 'ab|cd','ab\\cd', 'ab<cd',
      'ab,cd', 'ab>cd', 'ab?cd', 'ab/cd',
    ].each do |str|
      it "should not match '#{str}'" do
        expect(str.match(/^#{re}$/)).to be_nil
      end
    end
  end

  context "package_prefix_regexp" do
    re = repo.package_prefix_regexp
    [ '',
      '0', 'a', 'A',
      '0_', 'a_', 'A_', '0.', 'a.', 'A.', '0+', 'a+', 'A+', '0-', 'a-', 'A-',
      'a0', 'aa', 'aA', 'A0', 'Aa', 'AA',
      'apache22', 'jack_mixer', 'last.fm'
    ].each do |str|
      it "should match '#{str}'" do
        expect(str.match(/^#{re}$/)).to_not be_nil
      end
    end
    [ ' ', '  ',

      'ab cd', 'ab`cd', 'ab!cd', 'ab@cd', 'ab#cd', 'ab$cd', 'ab%cd', 'ab^cd',
      'ab&cd', 'ab*cd', 'ab(cd', 'ab)cd', 'ab)cd', 'ab{cd', 'ab}cd', 'ab[cd',
      'ab]cd', 'ab:cd', 'ab;cd', 'ab"cd', 'ab\'cd', 'ab|cd','ab\\cd', 'ab<cd',
      'ab,cd', 'ab>cd', 'ab?cd', 'ab/cd',
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
      '~!@#$%^&*())-+=_{}[]:;\'"|' => '~!@#$%^&*())-+=_{}[]:;\'"|',
      '.' => '\\.'
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
      '~!@#$%^&*())-+=_{}[]:;\'"|' => '~!@#$%^&*())-+=_{}[]:;\'"|',
      '.' => '\\.'
    }.each do |unescaped,escaped|
      it "should map #{unescaped.inspect} to #{escaped.inspect}" do
        expect(repo.escape_package_prefix(unescaped)).to eq(escaped)
      end
    end
  end

  context "using fixture file ports-make-search.tar.gz" do
    let :facts do
      {
        :operatingsystem => :freebsd
      }
    end
    dir = File.join(File.dirname(__FILE__),'..','..','..','..','fixtures','modules', 'repoutil-fixtures','files')
    repo = Puppet::Util::RepoUtils.repoutil(:ports)
    Zlib::GzipReader.open(File.join(dir, "ports-make-search.txt.gz")) { |gz|
      repo.stubs(:make).with('-C', '/usr/ports', 'search', 'name=^').returns(gz.read)
    }
    repo.stubs(:make).with('-C', '/usr/ports', 'search', 'name=^nonexistent').returns("\n")

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
