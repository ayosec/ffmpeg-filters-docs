# frozen_string_literal: true

require "optparse"

FFDocs::Options = Struct.new(
  :versions,
  :output,
  :compress_css,
) do
  def self.parse!
    options = self.new

    OptionParser.new do |parser|
      parser.on(
        "-o DIRECTORY",
        "--output DIRECTORY",
        "Directory where files will be written."
      ) do |dir|
        options.output = dir
      end

      parser.on(
        "-v VERSIONS",
        "--versions VERSIONS",
        "Comma-separated lists of versions to include in the output.",
        "Each version can be a glob-like pattern, like '3.*'."
      ) do |versions|
        options.versions = versions.split(",")
      end

      parser.on(
        "-C",
        "--compress-css",
        "Compress generated CSS files."
      ) do
        options.compress_css = true
      end
    end.parse!

    options
  end
end
