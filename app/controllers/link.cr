require "uuid"

module App::Controllers
  class LinkController < App::Lib::BaseController
    include App::Models
    include App::Lib
    include App::Services

    def initialize(@env : HTTP::Server::Context)
      ClickTracker.init
      super(@env)
    end

    def create
      user = current_user
      body = parse_body(["url"])
      url = body["url"].to_s

      query = Database::Query.where(url: url, user_id: user.id.as(String)).limit(1)
      existing_link = Database.all(Link, query, preload: [:clicks]).first?
      if existing_link
        return render_json({"data" => App::Serializers::Link.new(existing_link)})
      end

      link = Link.new
      link.id = UUID.v4.to_s
      link.url = url
      link.user = user
      link.slug = SlugService.shorten_url(url, user.id.to_s)

      changeset = Database.insert(link)
      if !changeset.valid?
        raise App::UnprocessableEntityException.new(@env, map_changeset_errors(changeset.errors))
      end

      link.clicks = [] of App::Models::Click

      render_json({"data" => App::Serializers::Link.new(link)}, 201)
    end

    def redirect
      slug = @env.params.url["slug"]

      link_data = nil
      Database.raw_query("SELECT id, url FROM links WHERE slug = (?) LIMIT 1", slug) do |result|
        if result.move_next
          link_data = {result.read(String), result.read(String)}
        end
      end
      raise App::NotFoundException.new(@env) unless link_data

      remote_address = @env.request.headers["Cf-Connecting-Ip"]?.try(&.presence) || @env.request.remote_address.try &.to_s
      user_agent_str = @env.request.headers["User-Agent"]? || "Unknown"
      client_ip = IpLookup.extract_ip(remote_address) || "Unknown"

      @env.response.status_code = 301
      @env.response.headers["Connection"] = "close"

      @env.response.headers["Location"] = link_data[1]
      @env.response.headers["X-Forwarded-For"] = client_ip
      @env.response.headers["User-Agent"] = user_agent_str

      spawn track_click(link_data[0], client_ip, user_agent_str)
    end

    def list_all
      user = current_user
      limit, cursor = pagination_params

      query = Database::Query.where(user_id: user.id.as(String))
      query = query.where("id < ?", cursor) if cursor
      query = query.order_by("id DESC").limit(limit + 1)

      links = Database.all(Link, query)

      paginated_response(links, limit) { |link| App::Serializers::Link.new(link) }
    end

    def get
      user = current_user
      link_id = @env.params.url["id"]

      query = Database::Query.where(id: link_id.as(String), user_id: user.id.as(String)).limit(1)
      link = Database.all(Link, query).first?
      raise App::NotFoundException.new(@env) if link.nil?

      clicks_query = Database::Query.where(link_id: link_id.as(String))
                                   .order_by("id DESC")
                                   .limit(100)
      link.clicks = Database.all(Click, clicks_query)

      render_json({"data" => App::Serializers::Link.new(link)})
    end

    def list_clicks
      user = current_user
      link_id = @env.params.url["id"]

      # Verify link exists and belongs to user
      link_query = Database::Query.where(id: link_id.as(String), user_id: user.id.as(String)).limit(1)
      link = Database.all(Link, link_query).first?
      raise App::NotFoundException.new(@env) if link.nil?

      limit, cursor = pagination_params

      query = Database::Query.where(link_id: link_id.as(String))
      query = query.where("id < ?", cursor) if cursor
      query = query.order_by("id DESC").limit(limit + 1)

      clicks = Database.all(Click, query)

      paginated_response(clicks, limit) { |click| App::Serializers::Click.new(click) }
    end

    def update
      user = current_user
      id = @env.params.url["id"]
      body = parse_body(["url"])
      new_url = body["url"].to_s

      query = Database::Query.where(id: id).limit(1)
      link = Database.all(Link, query, preload: [:clicks]).first?

      raise App::NotFoundException.new(@env) if link.nil?
      raise App::ForbiddenException.new(@env) if link.user_id != user.id

      # Check for existing URL
      existing_query = Database::Query.where(url: new_url, user_id: user.id.to_s).limit(1)
      if Database.all(Link, existing_query).first?
        raise App::UnprocessableEntityException.new(@env, { "url" => ["URL already exists"] })
      end

      link.url = new_url
      link.slug = SlugService.shorten_url(new_url, user.id.to_s)

      changeset = Database.update(link)
      if !changeset.valid?
        raise App::UnprocessableEntityException.new(@env, map_changeset_errors(changeset.errors))
      end

      render_json({"data" => App::Serializers::Link.new(link)})
    end

    def delete
      user = current_user
      id = @env.params.url["id"]

      link = Database.get(Link, id)
      raise App::NotFoundException.new(@env) if !link
      raise App::ForbiddenException.new(@env) if link.user_id != user.id

      result = Database.raw_exec("DELETE FROM links WHERE id = (?)", link.id)
      if result.rows_affected == 0
        raise App::UnprocessableEntityException.new(@env, { "id" => ["Row delete failed"] })
      end

      @env.response.status_code = 204
    end

    private def current_user : User
      @env.get("user").as(User)
    end

    private def track_click(link_id, client_ip, user_agent_str)
      source = @env.params.query["utm_source"]? || "Direct"
      referer = @env.request.headers["Referer"]?.try { |r| begin URI.parse(r).host rescue r end } || source

      ClickTracker.track(
        link_id: link_id,
        client_ip: client_ip,
        user_agent: user_agent_str,
        source: source,
        referer: referer
      )
    end

    private def pagination_params
      limit = (@env.params.query["limit"]? || "100").to_i
      cursor = @env.params.query["cursor"]?
      {limit, cursor}
    end

    private def paginated_response(items, limit)
      has_more = items.size > limit
      items = items[0...limit] if has_more
      next_cursor = has_more ? items.last.id : nil

      render_json({
        "data" => items.map { |item| yield item },
        "pagination" => {
          "has_more" => has_more,
          "next" => next_cursor
        }
      })
    end
  end
end
