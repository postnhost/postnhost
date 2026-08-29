module Postnhost
  class Categories::TranslationsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_category

    def create
      language_ids = params[:language_ids] || []

      language_ids.each do |language_id|
        Postnhost::Translation::CategoryVariantJob.perform_later(@category.id, language_id.to_i)

        @category.category_variants.create!(language: Postnhost::Language.find_by(id: language_id.to_i), generating: true)
      end

      redirect_to category_variants_path(@category)
    end

    private

    def load_category
      @category = Postnhost::Category.find(params[:category_id])
    end
  end
end
