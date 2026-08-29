module Postnhost
  class ApplicationController < ::ApplicationController
    include Postnhost::Authentication
    include Pagy::Method

    # Base locale before public LanguageSwitcher; avoids leaking I18n.locale into CMS/tests.
    prepend_before_action :set_cms_locale

    around_action :use_postnhost_timezone

    helper_method :current_setting

    helper Postnhost::ApplicationHelper
    helper Postnhost::ArticleHelper
    helper Postnhost::CategoryHelper
    helper Postnhost::CommonCssHelper
    helper Postnhost::NavigationHelper
    helper Postnhost::PagyHelper
    helper Postnhost::PublicPagesHelper
    helper Postnhost::SeoHelper
    helper Postnhost::SettingsHelper

    private

    def current_setting
      @current_setting ||= Postnhost::Setting.current
    end

    def set_cms_locale
      I18n.locale = I18n.default_locale
    end

    def use_postnhost_timezone(&)
      Time.use_zone(current_setting.effective_timezone_name, &)
    end
  end
end
