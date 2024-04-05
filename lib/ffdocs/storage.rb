require "json"
require "logger"
require "pathname"
require "zlib"

require_relative "source_docs"

class FFDocs::Storage

  DATA_FILE = Pathname.new(File.expand_path("../data/ffmpeg.tar.zst", __FILE__))

  CACHE_DIR = Pathname.new(
    ENV["FFDOCS_CACHE"] ||
      "#{ENV["XDG_CACHE_HOME"] || "#{ENV["HOME"]}/.cache"}/ffmpeg-filters-docs"
  )

  def initialize
    @data_dir = CACHE_DIR.join("ffmpeg-data")
    if @data_dir.directory?
      FileUtils.rm_r(@data_dir)
    end

    @data_dir.mkpath

    if not system("tar", "-C", @data_dir.to_s, "-xf", DATA_FILE.to_s)
      raise "Can't get data from #{DATA_FILE}"
    end
  end

  memoize def releases
    @data_dir
      .children
      .map {|dir| dir.join("tag.json").read }
      .map {|tag| ::FFDocs::SourceDocs::VersionTag.from_json(tag) }
      .sort
      .reverse
  end

  def get_file(version, path)
    file = @data_dir.join(version.tag).join(path)
    if file.exist?
      file.read(encoding: "UTF-8")
    end
  end

  module SyncData

    GIT_URL = "https://github.com/FFmpeg/FFmpeg.git"

    REPOSITORY_DIR = CACHE_DIR.join("ffmpeg.git")

    extend self

    def run!
      # Fetch/update the FFmpeg repository.
      if not REPOSITORY_DIR.directory?
        REPOSITORY_DIR.parent.mkpath
        REPOSITORY_DIR.parent.join("CACHEDIR.TAG").write("")

        if not REPOSITORY_DIR.directory?
          git "clone", "--bare", "--filter=tree:0", GIT_URL, REPOSITORY_DIR.to_s, chdir: false
        else
          git "fetch", "--quiet", "--tags"
        end
      end

      # Get a list of tags for the latest release of each major version.
      version_tags = {}

      git("tag").each_line do |tag|
        tag.chomp!
        commit, date = git("log", "-1", "--format=%H %ct", tag).split

        vt = ::FFDocs::SourceDocs::VersionTag.parse(
          tag,
          commit,
          Time.at(Integer(date)),
        )

        if vt
          version_tags[vt.major] = [ vt, version_tags[vt.major] ].compact.max
        end
      end

      # Download the needed files for each version.
      Dir.mktmpdir do |tmpdir|
        tmpdir = Pathname.new(tmpdir)

        version_tags.each_value do |version_tag|
          ver_dir = tmpdir.join(version_tag.tag)
          ver_dir.mkdir

          ::FFDocs.log.info "Getting files for tag #{version_tag.tag} ..."

          ver_dir.join("tag.json").write(version_tag.to_json)

          [
            FFDocs::SourceDocs::CHANGELOG_FILE,
            FFDocs::SourceDocs::Collection::SOURCE_FILE,
          ].each do |path|
            output = ver_dir.join(path)
            if data = git("show", [ version_tag.tag, path ].join(":"), ignore_errors: true)
              output.parent.mkpath
              output.write(data)
            end
          end
        end

        DATA_FILE.parent.mkpath
        system(
          { "ZSTD_CLEVEL" => "19" },
          "tar",
          "--sort=name",
          "--mtime=2000-01-01T00:00:00Z",
          "--owner=0",
          "--group=0",
          "--numeric-owner",
          "--format=ustar",
          "--zstd",
          "-cf", DATA_FILE.to_s,
          ".",
          chdir: tmpdir.to_s,
        )
      end
    end

    private def git(*args, chdir: true, ignore_errors: false)
      workdir = chdir ? REPOSITORY_DIR : "."

      popen_args = {}

      if ignore_errors
        popen_args[:err] = "/dev/null"
      end

      child = IO.popen(%w(git) + args, chdir: workdir, **popen_args)
      output = child.read

      Process.waitpid(child.pid)
      if not $?.success?
        if ignore_errors
          return nil
        else
          raise "Git failed with: #$?"
        end
      end

      output
    end
  end

end
