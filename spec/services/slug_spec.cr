require "../spec_helper"

describe App::Services::SlugService do
  it "creates stable URL-safe slugs" do
    slug = App::Services::SlugService.shorten_url("https://example.com", 1_i64)

    slug.should eq(App::Services::SlugService.shorten_url("https://example.com", 1_i64))
    slug.size.should eq(8)
    slug.should match(/\A[A-Za-z0-9_-]+\z/)
  end

  it "creates distinct slugs for distinct URLs" do
    App::Services::SlugService.shorten_url("https://example.com/one", 1_i64)
      .should_not eq(App::Services::SlugService.shorten_url("https://example.com/two", 1_i64))
  end
end
