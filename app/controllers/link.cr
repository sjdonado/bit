module App::Controllers
  class LinkController < App::Lib::BaseController
    include App::Models
    include App::Lib
    include App::Services

    def initialize(@env : HTTP::Server::Context)
      super(@env)
    end

    def create
      body = parse_body(["url"])
      url = body["url"].to_s

      query = Database::Query.where(url: url, user_id: current_user_id).limit(1)
      existing_link = Database.all(Link, query, preload: [:clicks]).first?
      if existing_link
        return render_json({"data" => App::Serializers::Link.new(existing_link)})
      end

      link = Link.new
      link.url = url
      link.user_id = current_user_id
      link.slug = SlugService.shorten_url(url, current_user_id)

      changeset = Database.insert(link)
      if !changeset.valid?
        raise App::UnprocessableEntityException.new(@env, map_changeset_errors(changeset.errors))
      end

      inserted_link = Database.get!(Link, changeset.instance.id)

      render_json({"data" => App::Serializers::Link.new(inserted_link)}, 201)
    end

    def list_all
      limit, cursor = pagination_params

      query = Database::Query.where(user_id: current_user_id)
      query = query.where("id < ?", cursor) if cursor
      query = query.order_by("id DESC").limit(limit + 1)

      links = Database.all(Link, query)

      paginated_response(links, limit) { |link| App::Serializers::Link.new(link) }
    end

    def get
      link_id = @env.params.url["id"].to_i64

      query = Database::Query.where(id: link_id, user_id: current_user_id).limit(1)
      link = Database.all(Link, query).first?
      raise App::NotFoundException.new(@env) if link.nil?

      clicks_query = Database::Query.where(link_id: link_id)
                                   .order_by("id DESC")
                                   .limit(100)
      link.clicks = Database.all(Click, clicks_query)

      render_json({"data" => App::Serializers::Link.new(link)})
    end

    def list_clicks
      link_id = @env.params.url["id"].to_i64

      # Verify link exists and belongs to user
      link_query = Database::Query.where(id: link_id, user_id: current_user_id).limit(1)
      link = Database.all(Link, link_query).first?
      raise App::NotFoundException.new(@env) if link.nil?

      limit, cursor = pagination_params

      query = Database::Query.where(link_id: link_id)
      query = query.where("id < ?", cursor) if cursor
      query = query.order_by("id DESC").limit(limit + 1)

      clicks = Database.all(Click, query)

      paginated_response(clicks, limit) { |click| App::Serializers::Click.new(click) }
    end

    def update
      id = @env.params.url["id"].to_i64
      body = parse_body(["url"])
      new_url = body["url"].to_s

      query = Database::Query.where(id: id).limit(1)
      link = Database.all(Link, query, preload: [:clicks]).first?

      raise App::NotFoundException.new(@env) if link.nil?
      raise App::ForbiddenException.new(@env) if link.user_id != current_user_id

      # Check for existing URL
      existing_query = Database::Query.where(url: new_url, user_id: current_user_id).limit(1)
      if Database.all(Link, existing_query).first?
        raise App::UnprocessableEntityException.new(@env, { "url" => ["URL already exists"] })
      end

      link.url = new_url
      link.slug = SlugService.shorten_url(new_url, current_user_id)

      changeset = Database.update(link)
      if !changeset.valid?
        raise App::UnprocessableEntityException.new(@env, map_changeset_errors(changeset.errors))
      end

      render_json({"data" => App::Serializers::Link.new(link)})
    end

    def delete
      id = @env.params.url["id"].to_i64

      link = Database.get(Link, id)
      raise App::NotFoundException.new(@env) if !link
      raise App::ForbiddenException.new(@env) if link.user_id != current_user_id

      result = Database.raw_exec("DELETE FROM links WHERE id = (?)", link.id)
      if result.rows_affected == 0
        raise App::UnprocessableEntityException.new(@env, { "id" => ["Row delete failed"] })
      end

      @env.response.status_code = 204
    end

    private def current_user : User
      @env.get("user").as(User)
    end

    private def current_user_id : Int64
      current_user.id.as(Int64)
    end

    private def pagination_params
      limit = (@env.params.query["limit"]? || "100").to_i32
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
