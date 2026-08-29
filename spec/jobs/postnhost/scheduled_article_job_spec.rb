require "rails_helper"

RSpec.describe Postnhost::ScheduledArticleJob, type: :job do
  let!(:default_language) { create(:language, :default) }

  it "delegates a due schedule to the shared publishing service" do
    article = create(:article, language: default_language, scheduled_at: 1.minute.ago, scheduled_job_id: "job-id")
    job = described_class.new
    allow(job).to receive(:job_id).and_return("job-id")

    expect { job.perform(article.id) }.to change(Postnhost::Snapshot::Article, :count).by(1)
    expect(article.reload.scheduled_at).to be_nil
    expect(article.scheduled_job_id).to be_nil
  end

  it "is idempotent when the schedule does not match the executing job" do
    article = create(:article, language: default_language, scheduled_at: 1.minute.ago, scheduled_job_id: "other-job")
    job = described_class.new
    allow(job).to receive(:job_id).and_return("job-id")

    expect { job.perform(article.id) }.not_to change(Postnhost::Snapshot::Article, :count)
  end

  it "records a validation error without raising when a scheduled draft is invalid" do
    article = create(:article, language: default_language, scheduled_at: 1.minute.ago, scheduled_job_id: "job-id")
    article.update_columns(title: nil)
    job = described_class.new
    allow(job).to receive(:job_id).and_return("job-id")

    expect { job.perform(article.id) }.not_to raise_error
    expect(article.reload.publication_error).to eq("title can't be blank")
    expect(article).not_to be_published
  end

  it "uses the dedicated publishing queue" do
    expect(described_class.queue_name).to eq("publishing")
  end

  it "has priority 1" do
    expect(described_class.priority).to eq(1)
  end
end
