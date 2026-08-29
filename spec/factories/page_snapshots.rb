FactoryBot.define do
  factory :page_snapshot, class: "Postnhost::Snapshot::Page" do
    page
    language { page.language }
    paper_trail_version { page.paper_trail.save_with_version }
    title { page.title }
    title_tag { page.title_tag }
    meta_description { page.meta_description }
    content { page.content }
    slug { page.slug }
    published_at { Time.current }
  end
end
