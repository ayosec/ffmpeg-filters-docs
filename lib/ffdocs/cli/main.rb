#!/usr/bin/env ruby

require_relative "../../ffdocs"
require_relative "options"

module FFDocs::CLI
  class Main

    attr_reader :options, :storage, :website

    def initialize
      @options = ::FFDocs::Options.parse!
      @storage = ::FFDocs::Storage.new

      @website = ::FFDocs::View::Website.new(options)
    end

    def run!
      # Track first version where an item is seen.
      first_version_items = {}

      # Parse sources for each version and generate the HTML files.
      storage.releases.sort.each do |release|
        if not options.versions.nil?
          matched = options.versions.any? do |v|
            v == release.version || File.fnmatch?(v, release.version)
          end

          next if not matched
        end

        # Download and parse the source of the `filters.texi` documentation.
        source =
          begin
            FFDocs::SourceDocs::Collection.new(storage, release)
          rescue FFDocs::SourceDocs::SourceNotFound
            next
          end

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
      website.render
    end

  end
end
