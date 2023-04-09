require "typhoeus"
require "json"

# Access to repository data.
#
# It uses the mirror in GitHub, so it get access to the `doc/filters.texi` file
# in each version without a clone of the repository.
class FFDocs::SourceDocs::Repository

  QUERY_URL = "https://api.github.com/repos/FFmpeg/FFmpeg/"

  class RequestFailed < StandardError; end
  class InvalidPath < StandardError; end

  def initialize
    @github_token = ENV["GITHUB_TOKEN"].dup.freeze
  end

  def tags
    url = "tags?per_page=100"
    Enumerator.new do |yielder|
      loop do
        response = get(url)
        response_body = JSON.parse(response.body)

        # Collect commit data.
        commit_data = multi_get(
          response_body.each_with_object({}) do |tag, reqs|
            reqs[tag["name"]] = tag.dig("commit", "url")
          end
        )

        response_body.each do |tag|
          committer = JSON.parse(commit_data[tag["name"]].body).dig("commit", "committer")

          tag_data = {
            "tag" => tag["name"],
            "commit" => tag.dig("commit", "sha"),
            "date" => committer["date"],
          }

          yielder << tag_data
        end

        # Find the next page, if any.
        link = response.headers["link"]
        if link_next = link.split(",").grep(/rel="next"/).first
          url = link_next[/<(.+?)>/, 1]
        else
          break
        end
      end
    end
  end

  def blob_hash(tag, path)
    components = path.split("/")
    basename = components.pop
    url = "git/trees/#{tag}?per_page=100"

    # Get the tree objects of the parents.
    while component = components.shift
      response = get(url)
      tree = JSON.parse(response.body)["tree"]
      item = tree.find {|i| i["path"] == component }

      if item.nil? || item["type"] != "tree"
        raise InvalidPath.new("#{component.inspect} is not a tree object.")
      end

      url = item["url"]
    end

    # Get the blob hash.
    response = get(url)
    tree = JSON.parse(response.body)["tree"]
    item = tree.find {|i| i["path"] == basename }

    if item.nil? || item["type"] != "blob"
      return nil
    end

    item["sha"]
  end

  def blob_data(blob_hash)
    headers = { "Accept" => "application/vnd.github.raw" }
    get("git/blobs/#{blob_hash}", headers: headers).body
  end

  private def make_request(uri, http_method, headers)
    ::FFDocs.log.info "[#{http_method.to_s.upcase}] #{uri}"
    url = case uri
          when /\Ahttps:/
            uri
          when /\A\//
            url = URI(QUERY_URL)
            url.path = uri
            url.to_s
          else
            [ QUERY_URL, uri ].join
          end

    req = Typhoeus::Request.new(url, method: http_method)

    headers.each_pair do |k, v|
      req.options[:headers][k] = v
    end

    if @github_token
      req.options[:headers]["Authorization"] = "Bearer #@github_token"
    end

    req
  end

  private def get(url, headers: {})
    response = make_request(url, :get, headers).run
    if not response.success?
      ::FFDocs.log.error "Request failed: #{response.status}\n#{response.body}"
      raise RequestFailed.new(response)
    end

    response
  end

  private def multi_get(urls, headers: {})
    hydra = Typhoeus::Hydra.new(max_concurrency: 16)
    responses = {}

    urls.each_pair do |key, url|
      req = make_request(url, :get, headers)
      req.on_complete do |response|
        if not response.success?
          ::FFDocs.log.error "Request failed: #{response.status}\n#{response.body}"
          raise RequestFailed.new(response)
        end

        responses[key] = response
      end

      hydra.queue(req)
    end

    hydra.run
    responses
  end

end
