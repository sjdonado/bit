require "uuid"
require "user_agent_parser"

require "../lib/controller.cr"
require "../lib/ip_lookup"

UserAgent.load_regexes(File.read("data/uap_core_regexes.yaml"))
IpLookup.load_mmdb("data/GeoLite2-Country.mmdb")

module App::Controllers::Link
  class Create < App::Lib::BaseController
    include App::Models
    include App::Lib
    include App::Services

    def call(env)
      user = env.get("user").as(User)
      body = parse_body(env, ["url"])
      url = body["url"].to_s

      query = Database::Query.where(url: url, user_id: user.id.as(String)).limit(1)
      existing_link = Database.all(Link, query, preload: [:clicks]).first?
      if existing_link
        response = {"data" => App::Serializers::Link.new(existing_link)}
        return response.to_json
      end

      link = Link.new
      link.id = UUID.v4.to_s
      link.url = url
      link.user = user
      link.slug = SlugService.shorten_url(url, user.id.to_s)

      changeset = Database.insert(link)
      if !changeset.valid?
        raise App::UnprocessableEntityException.new(env, map_changeset_errors(changeset.errors))
      end

      link.clicks = [] of App::Models::Click
      response = {"data" => App::Serializers::Link.new(link)}

      response.to_json
    end
  end

  class Index < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      slug = env.params.url["slug"]

      link = Database.get_by(Link, slug: slug)
      raise App::NotFoundException.new(env) if !link

      remote_address = env.request.remote_address.try &.to_s
      user_agent_str = env.request.headers["User-Agent"]? || "Unknown"

      client_ip = IpLookup.extract_ip(remote_address) || "Unknown"

      env.response.status_code = 301
      env.response.headers["Location"] = link.url!

      env.response.headers["X-Forwarded-For"] = client_ip
      env.response.headers["X-Forwarded-User-Agent"] = user_agent_str

      spawn do
        ip_lookup = client_ip != "Unknown" ? IpLookup.new(client_ip) : nil
        country = ip_lookup.try &.country.try &.code

        user_agent = user_agent_str != "Unknown" ? UserAgent.new(user_agent_str) : nil

        source = env.params.query["utm_source"]? || "Direct"
        referer_host = env.request.headers["Referer"]?.try { |r| begin URI.parse(r).host rescue r end } || source

        click = Click.new
        click.id = UUID.v4.to_s
        click.link = link
        click.country = country
        click.user_agent = user_agent_str
        click.browser = user_agent.try &.family
        click.os = user_agent.try &.os.try &.family
        click.referer = referer_host

        changeset = Database.insert(click)
        if changeset.errors.any?
          Log.error { "Logging click event failed: #{changeset.errors}" }
        end
      end
    end
  end

  class All < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      user = env.get("user").as(User)

      query = Database::Query.where(user_id: user.id.as(String))
      links = Database.all(Link, query, preload: [:clicks])

      response = {"data" => links.map { |link| App::Serializers::Link.new(link) }}
      response.to_json
    end
  end

  class Get < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      user = env.get("user").as(User)
      link_id = env.params.url["id"]

      query = Database::Query.where(id: link_id.as(String), user_id: user.id.as(String)).limit(1)
      link = Database.all(Link, query, preload: [:clicks]).first?

      raise App::NotFoundException.new(env) if link.nil?

      response = {"data" => App::Serializers::Link.new(link)}
      response.to_json
    end
  end

  class Update < App::Lib::BaseController
    include App::Models
    include App::Lib
    include App::Services

    def call(env)
      user = env.get("user").as(User)
      id = env.params.url["id"]
      body = parse_body(env, ["url"])

      query = Database::Query.where(id: id).limit(1)
      link = Database.all(Link, query, preload: [:clicks]).first?

      raise App::NotFoundException.new(env) if link.nil?
      raise App::ForbiddenException.new(env) if link.user_id != user.id

      new_url = body["url"].to_s

      existing_query = Database::Query.where(url: new_url, user_id: user.id.to_s).limit(1)
      existing_link = Database.all(Link, existing_query).first?

      if existing_link
        raise App::UnprocessableEntityException.new(env, { "url" => ["URL already exists"] })
      end

      link.url = new_url
      link.slug = SlugService.shorten_url(new_url, user.id.to_s)

      changeset = Database.update(link)
      if !changeset.valid?
        raise App::UnprocessableEntityException.new(env, map_changeset_errors(changeset.errors))
      end

      response = {"data" => App::Serializers::Link.new(link)}
      response.to_json
    end
  end

  class Delete < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      user = env.get("user").as(User)
      id = env.params.url["id"]

      link = Database.get(Link, id)
      raise App::NotFoundException.new(env) if !link

      if link.user_id != user.id
        raise App::ForbiddenException.new(env)
      end

      result = Database.raw_exec("DELETE FROM links WHERE id = (?)", link.id) # tempfix: Database.delete does not work
      if result.rows_affected == 0
        raise App::UnprocessableEntityException.new(env, { "id" => ["Row delete failed"] })
      end

      env.response.status_code = 204
    end
  end
end
