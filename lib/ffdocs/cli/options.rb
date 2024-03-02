# frozen_string_literal: true

require "optparse"

FFDocs::Options = Struct.new(
  :compress_css,
  :max_workers,
  :no_highlighter,
  :output,
  :project_url,
  :sync_ffmpeg_data,
  :versions,
) do
  def self.parse!
    options = self.new

    OptionParser.new do |parser|
      parser.on(
        "-C",
        "--compress-css",
        "Compress generated CSS files."
      ) do
        options.compress_css = true
      end

      parser.on(
        "-W COUNT",
        "--max-workers COUNT",
        "Maximum number of workers for writing the HTML files.",
        "Set to 0 to disable forking.",
        Integer,
      ) do |n|
        options.max_workers = n
      end

      parser.on(
        "-H",
        "--no-highlighting",
        "Disable syntax highlighting for code examples."
      ) do
        options.no_highlighter = true
      end

      parser.on(
        "-o DIRECTORY",
        "--output DIRECTORY",
        "Directory where files will be written."
      ) do |dir|
        options.output = dir
      end

      parser.on(
        "-U URL",
        "--project-url URL",
        "URL for the fmpeg-filters-docs project"
      ) do |url|
        options.project_url = url
      end

      parser.on(
        "-S",
        "--sync-ffmpeg-data",
        "Sync data from FFmpeg repository."
      ) do
        options.sync_ffmpeg_data = true
      end

      parser.on(
        "-v VERSIONS",
        "--versions VERSIONS",
        "Comma-separated lists of versions to include in the output.",
        "Each version can be a glob-like pattern, like '3.*'."
      ) do |versions|
        options.versions = versions.split(",")
      end
    end.parse!

    options
  end
end
