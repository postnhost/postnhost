FactoryBot.define do
  factory :page_variant_snapshot, class: "Postnhost::Snapshot::PageVariant" do
    page_variant
    page { page_variant.page }
    language { page_variant.language }
    paper_trail_version { page_variant.paper_trail.save_with_version }
    title { page_variant.title }
    content { page_variant.content }
    published_at { Time.current }
  end
end
