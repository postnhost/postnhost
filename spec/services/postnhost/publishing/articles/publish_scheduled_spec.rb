require "rails_helper"

RSpec.describe Postnhost::Publishing::Articles::PublishScheduled, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "publishes an article due for the current job" do
    article = create(
      :article,
      language: default_language,
      scheduled_at: 1.minute.ago,
      scheduled_job_id: "job-id"
    )

    result = described_class.call(article_id: article.id, job_id: "job-id")

    expect(result).to be_success
    expect(article.reload.article_snapshot).to be_present
    expect(article.scheduled_at).to be_nil
  end

  it "rejects a stale job" do
    article = create(:article, language: default_language, scheduled_at: 1.minute.ago, scheduled_job_id: "new-job")

    result = described_class.call(article_id: article.id, job_id: "old-job")

    expect(result).not_to be_success
    expect(article.reload.article_snapshot).to be_nil
  end

  it "returns not found when the article was deleted" do
    result = described_class.call(article_id: 0, job_id: "missing-job")

    expect(result).not_to be_success
    expect(result.status).to eq(:not_found)
    expect(result.errors).to eq(["Article was not found"])
  end

  it "records publication validation errors on the scheduled article" do
    article = create(
      :article,
      language: default_language,
      scheduled_at: 1.minute.ago,
      scheduled_job_id: "job-id"
    )
    article.update_column(:content, nil)

    result = described_class.call(article_id: article.id, job_id: "job-id")

    expect(result).not_to be_success
    expect(result.errors).to eq(["content can't be blank"])
    expect(article.reload.publication_error).to eq("content can't be blank")
  end
end
