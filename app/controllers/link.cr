require "uuid"

require "../lib/controller.cr"

module App::Controllers::Link
  class Create < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      body = parse_body(env, ["url"])

      link = Link.new
      link.id = UUID.v4.to_s
      link.url = body["url"].to_s
      link.slug = Random::Secure.urlsafe_base64(4)

      changeset = Database.insert(link)
      if !changeset.valid?
        raise App::UnprocessableEntityException.new(env, map_changeset_errors(changeset.errors))
      end

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

      spawn do
        link.click_counter = link.click_counter! + 1

        changeset = Database.update(link)
        if changeset.errors.any?
          Log.error { "Increase click counter failed: #{changeset.errors}" }
        end
      end

      env.redirect link.url!, 301
    end
  end

  class Read < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      id = env.params.url["id"]

      link = Database.get(Link, id)
      raise App::NotFoundException.new(env) if !link

      response = {"data" => App::Serializers::Link.new(link)}
      response.to_json
    end
  end

  class Update < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      id = env.params.url["id"]
      body = parse_body(env, ["url"])

      link = Database.get(Link, id)
      raise App::NotFoundException.new(env) if !link

      link.url = body["url"].to_s
      link.click_counter = 0

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
      id = env.params.url["id"]

      link = Database.get(Link, id)
      raise App::NotFoundException.new(env) if !link

      result = Database.raw_exec("DELETE FROM links WHERE id = (?)", link.id) # tempfix: Database.delete does not work
      if result.rows_affected == 0
        raise App::UnprocessableEntityException.new(env, { "id" => ["Row delete failed"] })
      end

      env.response.status_code = 204
    end
  end
end
