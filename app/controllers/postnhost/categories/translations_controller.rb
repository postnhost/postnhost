module Postnhost
  class Categories::TranslationsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_category

    def create
      result = Postnhost::Translation::Enqueue.call(record: @category, language_ids: Array(params[:language_ids]).map(&:to_i).uniq)
      redirect_to category_variants_path(@category), **(result.success? ? {} : { alert: result.errors.to_sentence })
    end

    private

    def load_category
      @category = Postnhost::Category.find(params[:category_id])
    end
  end
end
