module Postnhost
  module CommonCssHelper
    def icon(name, css_class: "w-4 h-4", subfolder: nil)
      path_parts = %w[app assets images postnhost icons]
      path_parts << subfolder if subfolder
      path_parts << "#{name}.svg"

      file_path = Postnhost::Engine.root.join(*path_parts)
      svg_content = File.read(file_path)
      svg_content.sub("<svg", "<svg class=\"#{css_class}\" aria-hidden=\"true\"").html_safe
    end

    # Button class helpers
    def button_classes(variant: :primary, disabled: false)
      base = "inline-flex items-center justify-center font-medium rounded-xl transition-all duration-200 text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 px-4 py-2"

      variant_classes = case variant
                        when :secondary
                          "bg-white text-gray-700 hover:bg-gray-50 border border-gray-200 focus:ring-gray-500"
                        when :danger
                          "bg-red-50 text-red-700 hover:bg-red-100 focus:ring-red-500"
                        else
                          "bg-gray-900 text-white hover:bg-gray-800 focus:ring-gray-900"
                        end

      disabled_classes = disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer"

      "#{base} #{variant_classes} #{disabled_classes}"
    end

    def icon_button_classes(variant: :default)
      base = "text-gray-400 transition-colors"

      hover_classes = case variant
                      when :danger then "hover:text-red-600"
                      else "hover:text-gray-600"
                      end

      "#{base} #{hover_classes}"
    end

    def page_header_classes
      "flex flex-col space-y-4 md:flex-row md:items-center md:justify-between md:space-y-0"
    end

    def form_card_classes
      "bg-white rounded-2xl border border-gray-200 p-6 space-y-6"
    end

    def error_container_classes
      "bg-red-50 border border-red-200 rounded-lg p-4"
    end

    def table_row_classes
      "px-6 py-4 hover:bg-gray-50 transition-colors duration-200"
    end

    def stats_badge_classes(variant: :blue)
      base = "items-center px-2.5 py-0.5 rounded-full text-xs font-medium"

      color_classes = case variant
                      when :purple then "bg-purple-100 text-purple-800"
                      when :green then "bg-green-100 text-green-800"
                      when :gray then "bg-gray-100 text-gray-800"
                      else "bg-blue-100 text-blue-800"
                      end

      "#{base} #{color_classes}"
    end

    def editor_button_classes(variant: :secondary)
      base = "w-full py-2.5 px-4 rounded-xl focus:outline-none focus:ring-2 focus:ring-offset-2 transition duration-200 text-sm font-medium text-center block"

      variant_classes = case variant
                        when :primary
                          "bg-green-600 text-white hover:bg-green-700 focus:ring-green-600"
                        else
                          "bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 focus:ring-gray-900 cursor-pointer"
                        end

      "#{base} #{variant_classes}"
    end

    # Form field class helpers
    def form_label_classes
      "block text-sm font-medium text-gray-700 mb-2"
    end

    def form_input_classes
      "block w-full rounded-xl border-gray-200 bg-gray-50 px-4 py-3 text-sm font-medium text-gray-900 transition-all duration-200 focus:border-gray-900 focus:bg-white focus:ring-0"
    end

    def form_textarea_classes
      "block w-full rounded-xl border-gray-200 bg-gray-50 px-4 py-3 text-sm font-medium text-gray-900 transition-all duration-200 focus:border-gray-900 focus:bg-white focus:ring-0"
    end
  end
end
