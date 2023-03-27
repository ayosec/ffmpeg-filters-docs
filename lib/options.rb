# frozen_string_literal: true

require "optparse"

Options = Struct.new(:versions, :output) do
  def self.parse!
    options = self.new

    OptionParser.new do |parser|
      parser.on(
        "-o DIRECTORY",
        "--output DIRECTORY",
        "Directory where files will be written."
      ) do |dir|
        parser.output = dir
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
