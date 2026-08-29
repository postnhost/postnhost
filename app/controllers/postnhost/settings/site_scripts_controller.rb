module Postnhost
  class Settings::SiteScriptsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_setting
    before_action :set_active_section
    before_action :load_site_script, only: %i[update destroy]

    layout "postnhost/product"

    def create
      @site_script = @setting.site_scripts.build(site_script_params)

      if @site_script.save
        redirect_to edit_settings_path(section: "scripts")
      else
        @new_site_script = @site_script
        render_edit_with_errors
      end
    end

    def update
      if @site_script.update(site_script_params)
        redirect_to edit_settings_path(section: "scripts")
      else
        @site_scripts = @site_scripts.map do |site_script|
          site_script.id == @site_script.id ? @site_script : site_script
        end
        render_edit_with_errors
      end
    end

    def destroy
      @site_script.destroy!
      redirect_to edit_settings_path(section: "scripts")
    end

    private

    def load_setting
      @setting = Postnhost::Setting.current
    end

    def set_active_section
      @active_section = "scripts"
      @new_site_script = Postnhost::SiteScript.new(setting: @setting)
      @site_scripts = @setting.site_scripts.order(:id)
    end

    def load_site_script
      @site_script = @setting.site_scripts.find(params[:id])
    end

    def render_edit_with_errors
      render "postnhost/settings/edit", status: :unprocessable_content
    end

    def site_script_params
      params.require(:site_script).permit(:placement, :script)
    end
  end
end
