require "pathname"
require "zlib"

require_relative "repository"
require_relative "version_tag"

class Storage

  STORAGE_DIR = Pathname.new(File.expand_path("../../target/storage", __FILE__))

  def initialize
    @repository = Repository.new

    if not STORAGE_DIR.directory?
      STORAGE_DIR.mkpath
      STORAGE_DIR.join("CACHEDIR.TAG").write("")
    end
  end

  # Return a list of tags for the latest release of each major version.
  def releases
    cached_file = STORAGE_DIR.join("releases")

    if cached_file.exist?
      r = cached_file.read.split.map {|v| VersionTag.parse(v) }
      return r
    end

    version_tags = {}
    @repository.tags.each do |tag|
      vt = VersionTag.parse(tag)
      next if vt.nil?

      version_tags[vt.major] = [ vt, version_tags[vt.major] ].compact.max
    end

    r = version_tags.values.sort.reverse
    cached_file.write(r.map(&:tag).join("\n"))
    r
  end

  # Download a blob from a specific tag.
  def download(tag, path)
    # Blob hash.
    cached_file_name = [ "hash", tag, path ].join("--").gsub(/[^a-zA-Z0-9._-]/) { "_%02X_" % $&.ord }
    cached_file = STORAGE_DIR.join(cached_file_name)

    if cached_file.exist?
      hash = cached_file.read
    else
      hash = @repository.blob_hash(tag, path)
      cached_file.write(hash)
    end

    return nil if hash.nil? || hash.empty?

    # Blob data
    gzcache(STORAGE_DIR.join("blob-#{hash}.gz")) do
      STDERR.puts "Download blob #{hash} for #{tag}:#{path} ..."
      @repository.blob_data(hash)
    end
  end

  # Cache the result of the block in a gzipped file.
  def gzcache(filename, &block)
    cached_file = STORAGE_DIR.join(filename)

    if cached_file.exist?
      Zlib::GzipReader.open(cached_file) do |gz|
        gz.read
      end
    else
      data = block.call
      Zlib::GzipWriter.open(cached_file, 9) do |gz|
        gz.write(data)
      end
      data
    end
  end

end
