module FFDocs::View
  module WebsiteHelpers

    FILE_LINKS_CACHE = {}

    def website
      renderer.website
    end

    def release
      renderer.release
    end

    def link_to_file(ref, label, extra_attrs = {})
      path_parent = path.parent
      cache_key = [path_parent, ref.object_id, label, extra_attrs]

      FILE_LINKS_CACHE[cache_key] ||=
        link_to(
          website.path_for(ref).relative_path_from(path_parent),
          label,
          extra_attrs,
        )
    end

    def link_to(url, label, extra_attrs = {})
      attrs =
        ::Haml::AttributeBuilder.build(
          true,
          "'",
          :html,
          nil,
          { href: url },
          extra_attrs
      )

      [
        %[<a#{attrs}>],
        Haml::Util.escape_html(label),
        %[</a>]
      ].join
    end

    def releases
      website.releases.map(&:release).sort.reverse.each
    end

    def nav_item_tree
      if rel = website.releases.find {|r| r.release == release }
        rel.
          source.
          groups.
          group_by(&:component).
          map do |name, groups|
            [ name, groups.group_by(&:media_type).to_a.sort ]
          end.
          sort
      else
        []
      end
    end

  end
end
