module Postnhost
  module LanguageSwitcher
    extend ActiveSupport::Concern

    included do
      before_action :set_language_data
    end

    private

    def set_language_data
      language = public_request_context.requested_language
      @current_language = language || ensure_default_language
      public_request_context.default_language = @current_language if @current_language.default?

      I18n.locale = @current_language.html_lang.to_sym

      @other_languages = Postnhost::Language.where.not(id: @current_language.id).order(:name)
    end

    def ensure_default_language
      public_request_context.default_language || create_english_default
    end

    def public_request_context
      @public_request_context ||= Postnhost::PublicRequestContext.for(request)
    end

    def localized_request?
      params[:locale].present?
    end

    def create_english_default
      language = Postnhost::Language.find_or_initialize_by(html_lang: "en") do |lang|
        lang.name = "English"
      end
      language.default = true
      language.save! if language.new_record?
      language
    end
  end
end
