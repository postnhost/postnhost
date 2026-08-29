module Postnhost
  class Pages::TranslationsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_page

    def new; end

    def create
      language_ids = params[:language_ids] || []

      language_ids.each do |language_id|
        Postnhost::Translation::PageVariantJob.perform_later(@page.id, language_id.to_i)

        @page.page_variants.create!(language: Postnhost::Language.find_by(id: language_id.to_i), generating: true)
      end

      redirect_to page_variants_path(@page)
    end

    private

    def load_page
      @page = Postnhost::Page.find(params[:page_id])
    end
  end
end
