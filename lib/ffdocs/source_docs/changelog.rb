# frozen_string_literal: true

module FFDocs::SourceDocs

  CHANGELOG_FILE = "Changelog"

  VersionChanges = Struct.new(:version, :items)

  class ChangeLog

    def initialize(storage = nil)
      @storage = storage || ::FFDocs::Storage.new
    end

    def latest
      release = @storage.releases.max

      blob = @storage.download(release.tag, CHANGELOG_FILE)
      lines = blob.each_line

      Enumerator.new do |yielder|
        loop do
          # Skip to the 'version' header.
          version = nil
          while true
            if lines.next =~ /\Aversion\s*(.*?):/
              version = $1
              break
            end
          end

          # Collect items
          items = []
          while true
            case lines.next.chomp
            when /\A\s*\Z/
              break if items.size > 0
            when /\A-(.*)/m
              items << $1.strip
            when /\A\s+(\S.*)/m
              items.last << " " << $1.strip
            end
          end

          yielder << VersionChanges.new(version, items)

        rescue StopIteration
          break
        end
      end
    end

  end

end
