module Postnhost
  module PagyHelper
    DEFAULT_PAGINATION_SLOTS = 7

    def pagination_nav(pagy)
      return "".html_safe if pagy.pages <= 1

      content_tag(:nav,
                  class: "flex items-center justify-center space-x-2",
                  aria: { label: I18n.t("postnhost.public.pagination.navigation", default: "Pagination") }) do
        safe_join(
          [
            pagination_previous_link(pagy),
            *pagination_series_fragments(pagy),
            pagination_next_link(pagy)
          ],
          ""
        )
      end
    end

    # Keep first pages canonical while preserving unrelated query parameters.
    def pagination_url(pagy, page)
      pagy.page_url(page == 1 ? :first : page)
    end

    def pagination_series(pagy)
      slots = pagy.options.fetch(:slots, DEFAULT_PAGINATION_SLOTS)
      return [] if slots.zero?
      return (1..pagy.pages).to_a if slots >= pagy.pages

      half = (slots - 1) / 2
      start = if pagy.page <= half
                1
              elsif pagy.page > pagy.pages - slots + half
                pagy.pages - slots + 1
              else
                pagy.page - half
              end

      (start...(start + slots)).to_a.tap do |series|
        next if pagy.options[:compact] || slots < DEFAULT_PAGINATION_SLOTS

        series[0] = 1
        series[1] = :gap unless series[1] == 2
        series[-2] = :gap unless series[-2] == pagy.pages - 1
        series[-1] = pagy.pages
      end
    end

    private

    def pagination_previous_link(pagy)
      label = I18n.t("postnhost.public.pagination.previous")
      enabled_classes = "inline-flex items-center justify-center p-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 hover:text-gray-700 cursor-pointer"
      disabled_classes = "inline-flex items-center justify-center p-2 text-sm font-medium text-gray-600 bg-gray-100 border border-gray-200 rounded-lg cursor-not-allowed opacity-50"

      if pagy.previous
        link_to(pagination_url(pagy, pagy.previous), class: enabled_classes, aria: { label: label }) do
          icon("chevron-left", css_class: "h-5 w-5")
        end
      else
        tag.span(icon("chevron-left", css_class: "h-5 w-5"),
                 class: disabled_classes,
                 aria: { label: label, disabled: true })
      end
    end

    def pagination_next_link(pagy)
      label = I18n.t("postnhost.public.pagination.next")
      enabled_classes = "inline-flex items-center justify-center p-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 hover:text-gray-700 cursor-pointer"
      disabled_classes = "inline-flex items-center justify-center p-2 text-sm font-medium text-gray-600 bg-gray-100 border border-gray-200 rounded-lg cursor-not-allowed opacity-50"

      if pagy.next
        link_to(pagination_url(pagy, pagy.next), class: enabled_classes, aria: { label: label }) do
          icon("chevron-right", css_class: "h-5 w-5")
        end
      else
        tag.span(icon("chevron-right", css_class: "h-5 w-5"),
                 class: disabled_classes,
                 aria: { label: label, disabled: true })
      end
    end

    def pagination_series_fragments(pagy)
      pagination_series(pagy).filter_map do |item|
        case item
        when Integer
          if item == pagy.page
            tag.span(item,
                     class: "px-3 py-2 text-sm font-medium text-white bg-gray-900 border border-gray-900 rounded-lg",
                     aria: { current: "page" })
          else
            link_to(item, pagination_url(pagy, item),
                    class: "px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 hover:text-gray-700 cursor-pointer")
          end
        when :gap
          tag.span("…", class: "px-3 py-2 text-sm font-medium text-gray-300")
        end
      end
    end
  end
end
