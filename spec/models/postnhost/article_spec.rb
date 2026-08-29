require "rails_helper"

RSpec.describe Postnhost::Article, type: :model do
  subject(:article) { build(:article) }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs
    example.run
    clear_enqueued_jobs
    clear_performed_jobs
    ActiveJob::Base.queue_adapter = original_adapter
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:language).optional }
    it { is_expected.to have_many(:article_authors).dependent(:destroy) }
    it { is_expected.to have_many(:authors).through(:article_authors) }
    it { is_expected.to have_many(:article_categories).dependent(:destroy) }
    it { is_expected.to have_many(:categories).through(:article_categories) }
    it { is_expected.to have_many(:article_variants).dependent(:destroy) }
    it { is_expected.to have_many(:article_suggestions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to allow_value(nil).for(:slug) }
    it { is_expected.to allow_value("my-valid-slug-1").for(:slug) }
    it { is_expected.not_to allow_value("Invalid Slug").for(:slug) }
    it { is_expected.not_to allow_value("slug_with_underscores").for(:slug) }

    it "rejects custom excerpt that exceeds character limit" do
      record = build(:article, custom_excerpt: "a" * 161)

      expect(record).not_to be_valid
      expect(record.errors[:custom_excerpt]).to include("must be 160 characters or fewer")
    end

    it "rejects slug used by a page" do
      create(:page, slug: "shared-slug")
      record = build(:article, slug: "shared-slug")

      expect(record).not_to be_valid
      expect(record.errors[:slug]).to include("has already been taken")
    end

    it "rejects primary language that duplicates an existing translation" do
      spanish = create(:language, :spanish)
      article = create(:article, language: create(:language, :default))
      create(:article_variant, article:, language: spanish)

      article.language = spanish

      expect(article).not_to be_valid
      expect(article.errors[:language_id]).to include("cannot duplicate an existing translation")
    end
  end

  describe "callbacks" do
    it "generates slug from title when slug is blank" do
      record = build(:article, title: "My New Article!", slug: nil)

      record.validate

      expect(record.slug).to eq("my-new-article")
    end

    it "increments generated slugs across article and page collisions" do
      create(:article, slug: "shared-title")
      create(:page, slug: "shared-title-1")
      record = build(:article, title: "Shared Title", slug: nil)

      record.validate

      expect(record.slug).to eq("shared-title-2")
    end

    it "normalizes blank slug to nil" do
      record = build(:article, title: nil, slug: " ")

      record.validate

      expect(record.slug).to be_nil
    end

    it "allows article without creator user" do
      record = build(:article, :without_user)

      expect(record).to be_valid
    end

    it "computes auto excerpt from content on save" do
      record = create(
        :article,
        custom_excerpt: nil,
        content: "<p>Authentication verifies identity.</p><p>Authorization defines permissions.</p><p>Extra text.</p>"
      )

      expect(record.auto_excerpt).to eq("Authentication verifies identity. Authorization defines permissions.")
    end

    it "assigns creator as the default author after create" do
      record = create(:article)

      expect(record.authors).to include(record.user)
      expect(record.article_authors.count).to eq(1)
    end
  end

  describe ".published" do
    it "returns only articles with snapshots" do
      public_article = create(:article, :published)
      private_article = create(:article)

      published_scope = described_class.published
      expect(published_scope).to include(public_article)
      expect(published_scope).not_to include(private_article)
    end
  end

  describe ".draft" do
    it "returns articles without snapshots" do
      public_article = create(:article, :published)
      private_article = create(:article)

      draft_scope = described_class.draft
      expect(draft_scope).to include(private_article)
      expect(draft_scope).not_to include(public_article)
    end
  end

  describe ".scheduled" do
    it "returns unpublished articles with a schedule" do
      scheduled_article = create(:article, :scheduled)
      draft_article = create(:article)
      published_scheduled = create(:article, :scheduled, :published)

      scheduled_scope = described_class.scheduled
      expect(scheduled_scope).to include(scheduled_article)
      expect(scheduled_scope).not_to include(draft_article)
      expect(scheduled_scope).not_to include(published_scheduled)
    end
  end

  describe ".with_status" do
    it "filters by published, draft, and scheduled" do
      published_article = create(:article, :published)
      draft_article = create(:article)
      scheduled_article = create(:article, :scheduled)

      expect(described_class.with_status("published")).to contain_exactly(published_article)
      expect(described_class.with_status("draft")).to contain_exactly(draft_article, scheduled_article)
      expect(described_class.with_status("scheduled")).to contain_exactly(scheduled_article)
      expect(described_class.with_status(nil)).to include(published_article, draft_article, scheduled_article)
    end
  end

  describe ".sorted_by" do
    it "orders by created_at in the requested direction" do
      older = create(:article)
      newer = create(:article)
      older.update_columns(created_at: 2.days.ago)
      newer.update_columns(created_at: 1.day.ago)

      expect(described_class.sorted_by("created_at_asc")).to eq([older, newer])
      expect(described_class.sorted_by("created_at_desc")).to eq([newer, older])
    end
  end

  describe ".normalize_status" do
    it "keeps known statuses and rejects unknown values" do
      expect(described_class.normalize_status("published")).to eq("published")
      expect(described_class.normalize_status("unknown")).to be_nil
      expect(described_class.normalize_status(nil)).to be_nil
    end
  end

  describe ".normalize_sort" do
    it "keeps known sort keys and defaults unknown values" do
      expect(described_class.normalize_sort("created_at_asc")).to eq("created_at_asc")
      expect(described_class.normalize_sort("title")).to eq("created_at_desc")
    end
  end

  describe ".top_picks" do
    it "returns only Top Picks block articles" do
      top_pick_article = create(:article, top_pick: true)
      regular_article = create(:article, top_pick: false)

      top_picks_scope = described_class.top_picks
      expect(top_picks_scope).to include(top_pick_article)
      expect(top_picks_scope).not_to include(regular_article)
    end
  end

  describe "#schedule_publication!" do
    it "saves schedule and job id" do
      record = create(:article)
      scheduled_time = 2.hours.from_now

      record.schedule_publication!(scheduled_time)

      expect(record.reload.scheduled_at.to_i).to eq(scheduled_time.to_i)
      expect(record.scheduled_job_id).to be_present
      expect(enqueued_jobs.last[:job]).to eq(Postnhost::ScheduledArticleJob)
    end
  end

  describe "#unschedule_publication!" do
    it "clears scheduling fields" do
      record = create(:article, :scheduled)

      record.unschedule_publication!

      expect(record.reload.scheduled_at).to be_nil
      expect(record.scheduled_job_id).to be_nil
    end

    it "removes the persisted Solid Queue job" do
      record = create(:article, :scheduled)
      stub_const("SolidQueue", Module.new)
      stub_const("SolidQueue::Job", Class.new do
        def self.find_by(...); end
      end)
      queued_job = instance_double(SolidQueue::Job, destroy: true)
      allow(SolidQueue::Job).to receive(:find_by).with(active_job_id: record.scheduled_job_id).and_return(queued_job)

      record.unschedule_publication!

      expect(queued_job).to have_received(:destroy)
    end
  end

  describe "#sync_publication_schedule!" do
    it "enqueues schedule when scheduled_at changed to present" do
      record = create(:article)
      time = 3.hours.from_now

      record.update!(scheduled_at: time)
      record.sync_publication_schedule!

      expect(record.reload.scheduled_job_id).to be_present
    end

    it "clears schedule when scheduled_at changed to nil" do
      record = create(:article)
      record.schedule_publication!(2.hours.from_now)
      record.update!(scheduled_at: nil)

      record.sync_publication_schedule!

      expect(record.reload.scheduled_at).to be_nil
      expect(record.scheduled_job_id).to be_nil
    end
  end
end
