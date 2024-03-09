#!/usr/bin/env ruby

require "concurrent"
require "etc"

require_relative "../../ffdocs"
require_relative "options"

module FFDocs::CLI
  class Main

    attr_reader :options, :storage, :website

    def initialize
      @options = ::FFDocs::Options.parse!
    end

    def run!
      # Sync data from FFmpeg instead of generating a new website.
      if options.sync_ffmpeg_data
        ::FFDocs::Storage::SyncData.run!
        return
      end

      executor = Concurrent::FixedThreadPool.new(options.max_workers || Etc.nprocessors)

      @storage = ::FFDocs::Storage.new
      @website = ::FFDocs::View::Website.new(options)

      # Track first version where an item is seen.
      first_version_items = {}

      # Parse sources for each version and generate the HTML files.
      source_promises = storage.releases.sort.map do |release|
        Concurrent::Promise.execute(executor: executor) do
          if not options.versions.nil?
            matched = options.versions.any? do |v|
              v == release.version || File.fnmatch?(v, release.version)
            end

            next if not matched
          end

          source =
            begin
              FFDocs::SourceDocs::Collection.new(options, storage, release)
            rescue FFDocs::SourceDocs::SourceNotFound
              next
            end

          [ release, source ]
        end
      end

      source_promises.each do |source_promise|
        result = source_promise.value!

        next if result.nil?
        release, source = result

        # Check what items have been added in this version.
        source.groups.each do |group|
          group.items.each do |item|
            key = [ group.component, group.media_type, item.name ].join("/")
            if v = first_version_items[key]
              item.first_version = v
            else
              first_version_items[key] = release.major
              item.first_version = release.major
            end
          end
        end

        website.register(release, source)
      end

      website.resolve_references
      website.render(executor)
    end

  end
end
