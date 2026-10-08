require "rails_helper"

RSpec.describe Postnhost::Translation::Enqueue do
  let!(:default_language) { create(:language, :default) }
  let(:language) { create(:language, :spanish) }

  %w[article page category].each do |kind|
    context "with #{kind} translations" do
      let(:record) { create(kind.to_sym, *(kind == "category" ? [] : [:published])) }
      let(:job_class) { Postnhost::Translation.const_get("#{kind.camelize}VariantJob") }

      [false, ActiveJob::EnqueueError.new("Queue unavailable")].each do |outcome|
        it "cleans up unqueued placeholders when enqueue #{outcome ? 'raises' : 'returns false'}, allowing retry" do
          if outcome
            allow(job_class).to receive(:perform_later).and_raise(outcome)
          else
            allow(job_class).to receive(:perform_later).and_return(false)
          end

          result = described_class.call(record:, language_ids: [language.id])
          expect(result.status).to eq(:service_unavailable)
          expect(result).not_to be_success
          expect(result.value).to eq(variants: [], job_ids: [], failed_language_ids: [language.id])
          expect(record.public_send("#{kind}_variants").reload).to be_empty
          expect(language.reload.article_variants_count).to eq(0) if kind == "article"

          allow(job_class).to receive(:perform_later).and_call_original
          expect { described_class.call(record:, language_ids: [language.id]) }.to have_enqueued_job(job_class).with(record.id, language.id)
          expect(record.public_send("#{kind}_variants").sole).to be_generating
        end
      end
    end
  end

  it "preserves queued work and existing translations while cleaning the failed remainder" do
    record = create(:article, :published)
    failed_language = create(:language, :russian)
    remaining_language = create(:language, name: "French", html_lang: "fr", default: false)
    existing_language = create(:language, name: "German", html_lang: "de", default: false)
    existing = create(:article_variant, article: record, language: existing_language)
    job_class = Postnhost::Translation::ArticleVariantJob
    allow(job_class).to receive(:perform_later).and_call_original
    allow(job_class).to receive(:perform_later).with(have_attributes(arguments: [record.id, failed_language.id])).and_return(false)

    result = described_class.call(record:, language_ids: [language.id, failed_language.id, remaining_language.id])
    expect(result.status).to eq(:service_unavailable)
    expect(job_class).not_to have_received(:perform_later).with(have_attributes(arguments: [record.id, remaining_language.id]))
    expect(result.value[:variants].sole.language_id).to eq(language.id)
    expect(result.value[:job_ids].size).to eq(1)
    expect(result.value[:failed_language_ids]).to eq([failed_language.id, remaining_language.id])
    expect(record.article_variants.pluck(:id)).to contain_exactly(existing.id, result.value[:variants].sole.id)
    expect(record.reload.article_variants_count).to eq(2)

    allow(job_class).to receive(:perform_later).with(have_attributes(arguments: [record.id, failed_language.id])).and_call_original
    retried = described_class.call(record:, language_ids: result.value[:failed_language_ids])
    expect(retried).to be_success
    expect(retried.value[:variants].map(&:language_id)).to eq([failed_language.id, remaining_language.id])
    expect(record.reload.article_variants_count).to eq(4)
    expect(job_class).to have_received(:perform_later).with(have_attributes(arguments: [record.id, language.id])).once
  end

  it "preserves an accepted job and its placeholder when an after-enqueue callback raises" do
    record = create(:article, :published)
    job_class = Postnhost::Translation::ArticleVariantJob
    callback = -> { raise StandardError, "After-enqueue callback failed" }
    job_class.set_callback(:enqueue, :after, callback)

    result = nil
    expect do
      result = described_class.call(record:, language_ids: [language.id])
    end.to have_enqueued_job(job_class).with(record.id, language.id)
    expect(result).to be_success
    expect(result.status).to eq(:accepted)
    expect(result.value[:job_ids].sole).to be_present
    expect(result.value[:variants].sole.id).to eq(record.article_variants.reload.sole.id)
    expect(record.article_variants.sole).to be_generating
    expect(result.value).not_to have_key(:failed_language_ids)
  ensure
    job_class.skip_callback(:enqueue, :after, callback) if callback
  end
end
