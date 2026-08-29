module Postnhost
  class SettingsController < ApplicationController
    include Postnhost::Settings::I18nManageable
    include Postnhost::Settings::NavigationManageable
    include Postnhost::Settings::SchemaManageable

    before_action :authenticate_user!
    before_action :load_setting
    before_action :set_active_section

    layout "postnhost/product"

    def edit
      set_i18n_editor_state if @active_section == "i18n"
      set_navigation_editor_state if @active_section == "navigation"
      set_schema_editor_state if @active_section == "schema"
      set_scripts_editor_state if @active_section == "scripts"
    end

    def update
      if @active_section == "i18n"
        update_i18n
      elsif @active_section == "navigation"
        update_navigation
      elsif @active_section == "schema"
        update_schema
      elsif @setting.update(setting_params)
        redirect_to edit_settings_path(section: @active_section), notice: "Settings were successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def load_setting
      @setting = Postnhost::Setting.current
    end

    def setting_params
      params.require(:setting).permit(
        :site_url,
        :site_indexing,
        :public_page_size,
        :site_logo,
        :og_image,
        :timezone,
        :author_pages_enabled,
        :search_enabled,
        :show_powered_by
      )
    end

    def set_scripts_editor_state
      @site_scripts = @setting.site_scripts.order(:id)
      @new_site_script = Postnhost::SiteScript.new(setting: @setting)
    end

    def set_active_section
      @active_section = params[:section].presence || "site"
    end
  end
end
