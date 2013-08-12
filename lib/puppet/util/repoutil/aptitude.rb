module Puppet::Util
  newrepoutil :aptitude, :parent => :apt do

    commands :aptitude=> "/usr/bin/aptitude"

    ENV['DEBIAN_FRONTEND'] = "noninteractive"

    def self.show_records(pattern)
        aptitude '-q=2', 'show', "~n#{pattern}"
    end

  end
end
