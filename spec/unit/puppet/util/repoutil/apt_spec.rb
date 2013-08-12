require 'spec_helper'

begin
  require 'zlib'
rescue LoadError
  have_zlib = false
else
  have_zlib = true
end

describe "Puppet::Util.repoutil(:apt)" do
  it "should exist" do
    Puppet::Util::RepoUtils.repoutil(:apt).should_not be_nil
  end

  repo = Puppet::Util::RepoUtils.repoutil(:apt)

  context "package_name_regexp" do
    re = repo.package_name_regexp
    [ '00', '0a', 'a0', 'aa', 
      '0.', 'a.', '0+', 'a+', '0-', 'a-', 
      'apache2', 'addres.freamework', 'anjuta-dbg'
    ].each do |str|
      it "should match '#{str}'" do
        str.match(/^#{re}$/).should_not be_nil
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
        str.match(/^#{re}$/).should be_nil
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
        str.match(/^#{re}$/).should_not be_nil
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
        str.match(/^#{re}$/).should be_nil
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
        repo.escape_package_name(unescaped).should == escaped
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
        repo.escape_package_prefix(unescaped).should == escaped
      end
    end
  end

  context "using fixture files apt-cache-*.tar.gz" do
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
        records.should be_a(Hash)
        records.should_not be_empty
      end
      it "should update records_cache" do
      end
    end

    context "retrieve_candidates('^')" do
      candidates = repo.retrieve_candidates('^')
      it "should return a nonempty hash" do
        candidates.should be_a(Hash)
        candidates.should_not be_empty
      end
      it "should update candidates_cache" do
      end
    end

    context "retrieve_records('^nonexistent')" do
      records = repo.retrieve_records('^nonexistent')
      it "should return an empty hash" do
        records.should be_a(Hash)
        records.should be_empty
      end
    end

    context "retrieve_candidates('^nonexistent')" do
      candidates = repo.retrieve_candidates('^nonexistent')
      it "should return an empty hash" do
        candidates.should be_a(Hash)
        candidates.should be_empty
      end
    end

  end
end
