# frozen_string_literal: true

require "redcarpet"

require_relative "helpers"

module FFDocs::View

  FFMPEG_COMMITS_URL_PREFIX = "https://git.ffmpeg.org/gitweb/ffmpeg.git/tree/"

  ReleaseRenderer = Struct.new(:website, :release, :source) do

    def render
      render_version_index
      render_version_changelog

      source.groups.
        group_by(&:component).
        each_pair \
      do |component, groups|
        render_component_list(component, groups)
      end

      source.groups.each do |group|
        group.items.each do |item|
          render_item(item)
        end
      end
    end

    def render_version_index(path = nil)
      path ||= website.path_for(release).join("index.html")

      ctx = ::FFDocs::View::RenderFrontVersionContext.new(self, path)
      main_body = website.version_front_template.render(ctx)

      html = website.with_layout(
        main_body,
        path: path,
        release: release,
        page_title: "FFmpeg #{release.version}",
        main_class: "version-front",
      )

      path.write(html)
    end

    def render_version_changelog
      path = website.path_for([ :changelog, release ])

      ctx = ::FFDocs::View::RenderChangelogContext.new(self, path)
      main_body = website.version_changelog_template.render(ctx)

      html = website.with_layout(
        main_body,
        path: path,
        release: release,
        page_title: "FFmpeg #{release.version}",
        main_class: "version-changelog",
      )

      path.write(html)
    end

    private def render_component_list(component, groups)
      # Index of the component, with all media_type groups.
      component_path = website.path_for(groups.first).parent.join("index.html")
      render_groups_list(
        "#{component} - FFmpeg #{release.version}",
        component_path,
        groups,
      )

      # Index for each component/media_type.
      groups.group_by(&:media_type).each do |media_type, groups|
        group_path = website.path_for(groups.first).join("index.html")
        render_groups_list(
          "#{component} / #{media_type} - FFmpeg #{release.version}",
          group_path,
          groups,
        )
      end
    end

    private def render_groups_list(page_title, path, groups)
      ctx = ::FFDocs::View::RenderListContext.new(self, groups, website, path)
      main_body = website.list_template.render(ctx)

      html = website.with_layout(
        main_body,
        path: path,
        release: release,
        page_title: page_title,
        main_class: "list",
      )

      path.write(html)
    end

    private def render_item(item)
      path = website.path_for(item)

      ctx = ::FFDocs::View::RenderItemContext.new(self, item, path)
      main_body = website.item_template.render(ctx)

      page_title = [
        item.name,
        " - FFmpeg ",
        release.version,
        " / ",
        item.group.component,
        " / ",
        item.group.media_type,
      ].join

      html = website.with_layout(
        main_body,
        path: path,
        item: item,
        release: release,
        main_class: "item",
        page_title: page_title,
      )

      path.write(html)
    end

  end

  Breadcrumb = Struct.new(:link, :label)

  RenderItemContext = Struct.new(:renderer, :item, :path) do

    include ::FFDocs::View::WebsiteHelpers

    def meta_description
      item.description
    end

    def meta_keywords
      %[ffmpeg, #{item.group.media_type.downcase} filter, #{item.name}]
    end

    def breadcrumbs
      Enumerator.new do |y|
        [
          [ renderer.website.path_for(renderer.release), renderer.release.version ],
          [ path.parent.parent, item.group.component ],
          [ path.parent, item.group.media_type ],
        ].each do |ref, label|
          y << Breadcrumb.new(ref.relative_path_from(path.parent), label)
        end

        y << Breadcrumb.new(nil, item.name)
      end
    end
  end

  RenderListContext = Struct.new(:renderer, :groups, :website, :path) do
    include ::FFDocs::View::WebsiteHelpers

    def breadcrumbs
      Enumerator.new do |y|
        y << Breadcrumb.new(
          renderer.website.path_for(renderer.release).relative_path_from(path.parent),
          renderer.release.version
        )

        components = groups.map(&:component).uniq
        if components.size == 1
          y << Breadcrumb.new(
            renderer.website.path_for(groups.first).parent.relative_path_from(path.parent),
            components.first
          )

          media_types = groups.map(&:media_type).uniq
          if media_types.size == 1
            y << Breadcrumb.new(
              renderer.website.path_for(groups.first).relative_path_from(path.parent),
              media_types.first
            )
          end
        end
      end
    end
  end


  RenderFrontVersionContext = Struct.new(:renderer, :path) do
    include ::FFDocs::View::WebsiteHelpers

    def commit_url(hash)
      [ FFMPEG_COMMITS_URL_PREFIX, hash ].join
    end

    def readme_info
      # Get the section about differences from the README.
      readme = File.read(File.expand_path("../../../../README.md", __FILE__))
      differences = readme[
          %r[
            <!--\s*differences\s*-->
            (.+?)
            <!--\s*end\s*differences\s*-->
          ]xm,
          1
      ]

      Redcarpet::Markdown
        .new(MarkdownIndexRender, context: self)
        .render(differences)
    end
  end


  RenderChangelogContext = Struct.new(:renderer, :path) do
    include ::FFDocs::View::WebsiteHelpers

    def release_changes
      versions = []
      changelog = ::FFDocs::SourceDocs::ChangeLog.new(renderer.source.storage)
      changelog.latest.each do |entry|
        major = entry.version.split(".").take(2).join(".")
        if major == renderer.release.major
          versions << entry
        end
      end

      versions.reverse
    end

  end

  class MarkdownIndexRender < Redcarpet::Render::HTML
    # Use `*...*` to mark specific links.
    def emphasis(text)
      case text
      when %r[(.*)\s+/\s+(.*)]
        component = $1
        media_type = $2
        group = @options[:context].renderer.source.groups.find do |group|
          group.media_type == media_type && group.component = component
        end

        if group
          @options[:context].link_to_file group, text
        else
          %[<em>#{text}</em>]
        end

      when "Other Vers."
        js = <<~JS
          (function(e) {
            e.open = true;

            requestAnimationFrame(() => e.scrollIntoView(true));
          })(document.querySelector(".other-versions"));

          return false;
        JS

        js = CGI.escapeHTML(js).gsub("\n", "&#10;");

        %[<a href="#other-versions-header" onclick="#{js}" >#{text}</a>]

      when "Version Matrix"
        @options[:context].link_to_file :version_matrix, text

      else
        %[<em>#{text}</em>]
      end
    end

    # Process `[highlight]` comments.
    def block_html(html)
      if html =~ %r|\A<!--\s*\[highlight\]\s*(.*?)\n+(.+)-->\Z|m
        text = $1
        code = $2.rstrip

        # Parse `filter:NAME` tags.
        text.gsub!(/filter:(\S+)/) do |m, x|
          filter_name = $1
          filter = catch :filter do
              @options[:context].renderer.source.groups.each do |group|
              group.items.each do |item|
                if item.name == filter_name
                  throw :filter, item
                end
              end
            end

            nil
          end

          if filter
            @options[:context].link_to_file filter, filter_name
          else
            "<code>#{filter_name}</code>"
          end
        end

        # Remove the prefix to indent the source.
        prefix = code[/\A\s+/]
        code = code.gsub(/^#{prefix}/, "")

        code = ::FFDocs::SourceDocs::HTMLAdapter::SyntaxHighlight.highlight(code)

        %[#{text}\n<pre class="code-snippet">#{code}</pre>]
      else
        html
      end
    end
  end

end
