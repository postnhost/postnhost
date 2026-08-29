module Postnhost
  class Navigation < ApplicationRecord
    self.table_name = "postnhost_navigations"

    belongs_to :setting, class_name: "Postnhost::Setting", touch: true
    has_many :navigation_items,
             -> { order(:container_kind, :parent_id, :position, :id) },
             class_name: "Postnhost::NavigationItem",
             dependent: :destroy,
             inverse_of: :navigation

    validates :setting_id, uniqueness: true

    def replace_tree!(tree:, locale_key:)
      locale = locale_key.to_s

      transaction do
        old_items = navigation_items.index_by(&:id)
        navigation_items.delete_all
        create_container_items!("header", tree.fetch("header", []), locale, old_items)
        create_container_items!("footer", tree.fetch("footer", []), locale, old_items)
        setting.touch
      end
    end

    private

    def create_container_items!(container_kind, items, locale, old_items)
      items.each_with_index do |item_payload, position|
        create_item!(parent: nil, payload: item_payload, context: {
                       container_kind: container_kind,
                       locale: locale,
                       position: position,
                       old_items: old_items
                     })
      end
    end

    def create_item!(parent:, payload:, context:)
      container_kind = context[:container_kind]
      locale = context[:locale]
      position = context[:position]
      old_items = context[:old_items]
      original_item = old_items[payload["id"].to_i]
      labels = (original_item&.label_translations || {}).deep_stringify_keys
      new_label = payload["label"].to_s.strip
      if new_label.blank?
        labels.delete(locale)
      else
        labels[locale] = new_label
      end

      item = navigation_items.create!(
        parent:,
        container_kind:,
        kind: payload["kind"],
        target_kind: payload["target_kind"].presence,
        target_id: payload["target_id"].presence,
        target_slug: payload["target_slug"].presence,
        url: payload["url"].presence,
        nofollow: ActiveModel::Type::Boolean.new.cast(payload["nofollow"]) || false,
        label_translations: labels,
        position:
      )

      payload["children"].to_a.each_with_index do |child_payload, child_position|
        create_item!(parent: item, payload: child_payload, context: {
                       container_kind: container_kind,
                       locale: locale,
                       position: child_position,
                       old_items: old_items
                     })
      end
    end
  end
end
