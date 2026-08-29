module Postnhost
  class TemplatesController < ApplicationController
    before_action :authenticate_user!
    layout "postnhost/product"

    def edit
      @template = Postnhost::Template.current
    end

    def update
      @template = Postnhost::Template.current

      if @template.update(template_params)
        redirect_to edit_template_path, notice: "Template settings were successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def template_params
      params.require(:template).permit(:name)
    end
  end
end
