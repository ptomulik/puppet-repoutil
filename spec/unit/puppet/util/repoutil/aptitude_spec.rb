require 'spec_helper'
require 'puppet/util/repoutil'

begin
  require 'zlib'
rescue LoadError
  have_zlib = false
else
  have_zlib = true
end

describe "Puppet::Util.repoutil(:aptitude)" do
  it "should exist" do
    expect(Puppet::Util::RepoUtils.repoutil(:aptitude)).to_not be_nil
  end

  repo = Puppet::Util::RepoUtils.repoutil(:aptitude)


  context "using fixture files aptitude-show.txt.gz and apt-cache-policy.txt.gz" do
    dir = File.join(File.dirname(__FILE__),'..','..','..','..','fixtures','modules', 'repoutil-fixtures','files')
    repo = Puppet::Util::RepoUtils.repoutil(:apt)
    Zlib::GzipReader.open(File.join(dir, "aptitude-show.txt.gz")) { |gz|
      repo.stubs(:aptitude).with('-q=2', 'show', '~n^').returns(gz.read)
    }
    Zlib::GzipReader.open(File.join(dir, "apt-cache-policy.txt.gz")) { |gz|
      repo.stubs(:aptcache).with('-q=2', '-a', 'policy', '^').returns(gz.read)
    }
    repo.stubs(:aptitude).with('-q=2', 'show', '~n^nonexistent').returns("\n")
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
