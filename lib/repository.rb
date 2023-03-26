require "faraday"
require "json"

# Access to repository data.
#
# It uses the mirror in GitHub, so it get access to the `doc/filters.texi` file
# in each version without a clone of the repository.
class Repository

  QUERY_URL = "https://api.github.com/repos/FFmpeg/FFmpeg/"

  class RequestFailed < StandardError; end
  class InvalidPath < StandardError; end

  def initialize
    @faraday = Faraday.new(url: QUERY_URL)

    if token = ENV["GITHUB_TOKEN"]
      @faraday.headers["Authorization"] = "Bearer #{token}"
    end
  end

  def tags
    url = "tags?per_page=100"
    Enumerator.new do |yielder|
      loop do
        response = get(url)

        JSON.parse(response.body).each do |tag|
          yielder << tag["name"]
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

  private def get(url, headers: nil)
    response = @faraday.get(url, nil, headers)
    if not response.success?
      STDERR.puts "Request failed: #{response.status}\n#{response.body}"
      raise RequestFailed.new(response)
    end

    response
  end

end
