require "uuid"

require "../lib/controller.cr"

module App::Controllers::Link
  class Create < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      json_params = env.params.json.to_h
      url = json_params.has_key?("url") ? json_params["url"] : nil
      raise App::BadRequestException.new(env, {"url" => "Required field"}) if !url

      link = Link.new
      link.id = UUID.v4.to_s
      link.url = url.to_s
      link.slug = Random::Secure.urlsafe_base64(4)

      changeset = Database.insert(link)

      if !changeset.valid?
        errors = {"errors" => map_changeset_errors(changeset.errors)}
        raise App::UnprocessableEntityException.new(env, errors)
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

      link = Database.get_by!(Link, slug: slug)

      spawn do
        link.click_counter = link.click_counter! + 1

        changeset = Database.update(link)
        if changeset.errors.any?
          Log.error { "Increase click counter failed: #{changeset.errors}" }
        end
      end

      env.redirect link.url!
    end
  end

  class Get < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      id = env.params.url["id"]

      link = Database.get!(Link, id)

      response = {"data" => App::Serializers::Link.new(link)}
      response.to_json
    end
  end

  class Update < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      id = env.params.url["id"]

      json_params = env.params.json.to_h
      url = json_params.has_key?("url") ? json_params["url"] : nil
      raise App::BadRequestException.new(env, {"url" => "Required field"}) if !url

      link = Database.get!(Link, id)
      link.url = url.to_s
      link.click_counter = 0

      changeset = Database.update(link)

      if !changeset.valid?
        errors = {"errors" => map_changeset_errors(changeset.errors)}
        raise App::UnprocessableEntityException.new(env, errors)
      end

      response = {"data" => App::Serializers::Link.new(link)}
      response.to_json
    end
  end

  # TODO: delete
end
