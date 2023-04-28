# frozen_string_literal: true

require "optparse"

FFDocs::Options = Struct.new(
  :compress_css,
  :no_highlighter,
  :output,
  :project_url,
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
