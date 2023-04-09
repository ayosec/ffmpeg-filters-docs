# frozen_string_literal: true

require "etc"
require "haml"
require "sassc"

require_relative "release_renderer"
require_relative "version_matrix_renderer"
require_relative "helpers"

module FFDocs::View
  class Website

    DEFAULT_OUTPUT_DIR = "target/website"

    CSS_SOURCE = File.expand_path("../styles/main.scss", __FILE__)

    ReleaseData = Struct.new(:release, :source)

    WebsiteFile = Struct.new(:release, :component, :media_type, :item, :path)

    class InvalidPathName < StandardError
      def self.check!(name)
        if name !~ /\A[a-zA-Z0-9_.-]+\Z/
          raise InvalidPathName.new(name)
        end

        name
      end
    end

    class RenderFailed < StandardError; end

    attr_reader :main_css_path, :releases

    def initialize(options)
      @project_url = options.project_url
      @output = Pathname.new(options.output || DEFAULT_OUTPUT_DIR)

      @output.mkdir if not @output.directory?
      @output.join("CACHEDIR.TAG").write("")

      init_css!(options)

      @releases = []
      @website_files = {}
    end

    def register(release, source)
      @releases << ReleaseData.new(release, source)

      # Ensure all directories are created before writing files.

      release_dir = path_for(release)
      release_dir.mkdir if not release_dir.directory?

      source.groups.each do |group|
        group_dir = path_for(group)

        # We have to check two levels of directories, since `media_type` is under
        # `component`.
        [ group_dir.parent, group_dir ].each do |dir|
          dir.mkdir if not dir.directory?
        end
      end
    end

    # When all items are loaded, we have to resolve `label:` links.
    def resolve_references
      ffmpeg_org_prefix = "https://ffmpeg.org/ffmpeg-filters.html#"
      ffmpeg_org_refs = %w(
        all commands filtergraph-escaping framesync
        primaries range space trc Filtergraph-syntax
      )

      @releases.each do |rd|
        # Collect the names and the `Item` instance for each item.
        all_items = {}
        rd.source.groups.each do |group|
          group.items.each do |item|
            all_items[item.name] = item
          end
        end

        # Traverse all HTML pages and replace <a href="label:..."> elements.
        rd.source.groups.each do |group|
          group.items.each do |item|
            item_parent_path = nil

            item.html.search("a[href]").each do |anchor|
              updated_href = nil

              case anchor["href"]
              when /\Alabel:(.+)\Z/m
                label = $1

                item_parent_path ||= path_for(item).parent

                if other_item = all_items[label]
                  updated_href = path_for(other_item).relative_path_from(item_parent_path)
                elsif ffmpeg_org_refs.include?(label)
                  updated_href = ffmpeg_org_prefix + label
                elsif other_item = rd.source.anchors[label]
                  updated_href = [
                    path_for(other_item).relative_path_from(item_parent_path),
                    label,
                  ].join("#")
                end

              when /\Ahttps?:/, /\A[^:]+\Z/
                # Ignore HTTP and local (i.e. no ":" character) URIs.
                next

              end

              if updated_href
                anchor["href"] = updated_href
              else
                STDERR.puts "Could not resolve link for #{anchor}."
              end
            end
          end
        end
      end
    end

    def render
      workers = Workers.new

      @releases.freeze

      workers.launch "version-matrix" do
        ::FFDocs::View::VersionMatrixRenderer.new(self).render
      end

      @releases.each do |rd|
        workers.launch rd.release.version do
          ::FFDocs::View::ReleaseRenderer.new(self, rd.release, rd.source).render
        end
      end

      workers.wait_all

      if not workers.failures.empty?
        raise RenderFailed.new("Failed for versions #{workers.failures.join(",")}")
      end
    end

    # Compile and store the main CSS file.
    private def init_css!(options)
      opts = {
        style: options.compress_css ? :compressed : :expanded,
        filename: CSS_SOURCE,
      }

      css = SassC::Engine.new(File.read(CSS_SOURCE), opts).render

      @main_css_path = @output.join(File.basename(CSS_SOURCE, ".scss") + ".css")
      @main_css_path.write(css)
    end

    # Compute the path for a specific item in the website.
    def path_for(obj)
      obj_key =
        case obj
        when ::FFDocs::SourceDocs::Group, ::FFDocs::SourceDocs::Item
          # Use the object identifier for heavy items.
          obj.object_id
        else
          obj
        end

      @website_files[obj_key] ||=
        case obj
        when ::FFDocs::SourceDocs::VersionTag
          @output.join(InvalidPathName.check!(obj.version))

        when ::FFDocs::SourceDocs::Group
          [ obj.component, obj.media_type ].
            map {|part| InvalidPathName.check!(part.gsub(" ", "-")) }.
            reduce(path_for(obj.release)) {|a, b| a.join(b) }

        when ::FFDocs::SourceDocs::Item
          path_for(obj.group).
            join(InvalidPathName.check!(obj.name) + ".html")

        when :version_matrix
          @output.join("version-matrix.html")

        else
          raise ArgumentError.new("Invalid object for #path_for: #{obj.inspect}")

        end
    end

    def with_layout(
      main_body,
      path:,
      page_title: nil,
      item: nil,
      release: nil,
      meta_description: nil,
      meta_keywords: nil,
      main_class: nil
    )
      @layout_template ||= compile_template("_layout")

      ctx = RenderLayoutContext.new
      ctx.website = self
      ctx.project_url = @project_url
      ctx.item = item
      ctx.path = path
      ctx.page_title = page_title
      ctx.release = release
      ctx.meta_description = meta_description
      ctx.meta_keywords = meta_keywords
      ctx.main_body = main_body
      ctx.main_class = main_class
      @layout_template.render(ctx)
    end

    memoize def item_template
      compile_template("item")
    end

    memoize def list_template
      compile_template("list")
    end

    memoize def version_front_template
      compile_template("version_front")
    end

    memoize def version_matrix_template
      compile_template("version_matrix")
    end

    private def compile_template(name)
      File.open(File.expand_path("../templates/#{name}.haml", __FILE__)) do |tpl|
        Haml::Template.new(tpl)
      end
    end

    class Workers
      NPROCS = Etc.nprocessors

      attr_reader :failures

      def initialize
        @pids = {}
        @failures = []
      end

      def launch(label, &block)
        while @pids.size >= NPROCS
          wait_one()
        end

        pid = fork(&block)
        @pids[pid] = label
      end

      def wait_one
        pid = Process.wait
        label = @pids.delete(pid)
        return if label.nil?

        if not $?.success?
          STDERR.puts "Worker for #{label.inspect} failed."
          @failures << label
        end
      end

      def wait_all
        wait_one while not @pids.empty?
      end
    end
  end

  RenderLayoutContext = Struct.new(
    :website,
    :project_url,
    :item,
    :page_title,
    :path,
    :release,
    :meta_description,
    :meta_keywords,
    :main_body,
    :main_class,
  ) do
    include ::FFDocs::View::WebsiteHelpers

    CSS_HREF_CACHE = {}

    def css_path
      CSS_HREF_CACHE[path.parent] ||=
        website.main_css_path.relative_path_from(path.parent)
    end
  end
end
