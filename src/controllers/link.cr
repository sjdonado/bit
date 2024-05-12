require "../lib/controller.cr"

module App::Controllers::Link
  class Create < App::Lib::BaseController
    include App::Models
    include App::Lib

    def call(env)
      params = env.params.json["link"].as(Hash)

      link = Link.new
      link.url = params["url"].as_s
      link.slug = Random::Secure.urlsafe_base64(4)

      changeset = Database.insert(link)

      if !changeset.valid?
        errors = {"errors" => map_changeset_errors(changeset.errors)}
        raise App::UnprocessableEntityException.new(env, errors.to_json)
      end

      App::Serializers::Link.new(link).to_json
    end
  end
end
