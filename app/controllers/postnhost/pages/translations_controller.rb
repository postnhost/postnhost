module Postnhost
  class Pages::TranslationsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_page

    def new; end

    def create
      result = Postnhost::Translation::Enqueue.call(record: @page, language_ids: Array(params[:language_ids]).map(&:to_i).uniq)
      redirect_to page_variants_path(@page), **(result.success? ? {} : { alert: result.errors.to_sentence })
    end

    private

    def load_page
      @page = Postnhost::Page.find(params[:page_id])
    end
  end
end
