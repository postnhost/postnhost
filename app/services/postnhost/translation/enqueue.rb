module Postnhost
  module Translation
    class Enqueue < BaseService
      def initialize(record:, language_ids:)
        @record = record
        @language_ids = language_ids
      end

      def call
        return success({ variants: [], job_ids: [] }) if language_ids.empty?

        kind = record.class.model_name.element
        return failure("Publish the source before generating translations") if record.respond_to?(:published?) && !record.published?

        languages = language_ids.map { |id| Language.find(id) }
        primary_id = record.respond_to?(:language_id) ? record.language_id : Language.blog_default&.id
        return failure("Cannot translate into the source language") if languages.any? { |language| language.id == primary_id }

        variants = record.class.transaction do
          languages.map { |language| record.public_send("#{kind}_variants").create!(language:, generating: true) }
        end
        enqueue_variants(variants, Translation.const_get("#{kind.camelize}VariantJob", false))
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages)
      rescue ActiveRecord::RecordNotFound
        failure("Language not found", status: :not_found)
      end

      private

      attr_reader :record, :language_ids

      def enqueue_variants(variants, job_class)
        jobs = []
        variants.each do |variant|
          job = enqueue(job_class, variant)
          unless job
            unqueued = variants.drop(jobs.size)
            unqueued.each(&:destroy!)
            return ServiceResult.new(
              value: { variants: variants.take(jobs.size), job_ids: jobs.map(&:job_id), failed_language_ids: unqueued.map(&:language_id) },
              errors: ["Could not queue all translations. Retry the failed languages."], status: :service_unavailable
            )
          end
          jobs << job
        end
        success({ variants:, job_ids: jobs.map(&:job_id) }, status: :accepted)
      end

      def enqueue(job_class, variant)
        job = job_class.new(record.id, variant.language_id)
        job_class.perform_later(job)
      rescue StandardError => e
        Rails.logger.error("Postnhost translation enqueue failed (#{e.class})")
        job if job&.successfully_enqueued?
      end
    end
  end
end
