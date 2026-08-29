import { Controller } from "@hotwired/stimulus"

const EXPANDED_ICON_CLASSES = ["rotate-0"]
const COLLAPSED_ICON_CLASSES = ["-rotate-90"]

export default class extends Controller {
  static targets = ["section"]
  static values = { storageKey: String }

  connect() {
    this.savedState = this.#readSavedState()
    this.sectionTargets.forEach(section => this.#syncSectionState(section))
  }

  toggle(event) {
    event.preventDefault()

    const sectionId = event.params.id
    if (!sectionId) return

    const section = this.sectionTargets.find(item => item.dataset.sectionId === sectionId)
    if (!section) return

    const isCollapsed = this.#isCollapsed(section)
    this.#setCollapsed(section, !isCollapsed)
    this.#persistSectionState(sectionId, !isCollapsed)
  }

  #syncSectionState(section) {
    const sectionId = section.dataset.sectionId
    if (!sectionId) return

    const hasSavedState = Object.prototype.hasOwnProperty.call(this.savedState, sectionId)
    const savedCollapsed = this.savedState[sectionId]
    const defaultCollapsed = section.dataset.defaultCollapsed === "true"
    const shouldCollapse = hasSavedState ? savedCollapsed : defaultCollapsed

    this.#setCollapsed(section, shouldCollapse)
  }

  #setCollapsed(section, collapsed) {
    const content = section.querySelector('[data-role="section-content"]')
    const button = section.querySelector('[data-role="section-toggle"]')
    const icon = section.querySelector('[data-role="section-icon"]')
    const accessory = section.querySelector('[data-role="section-accessory"]')
    if (!content || !button || !icon) return

    content.classList.toggle("hidden", collapsed)
    if (accessory) {
      accessory.style.visibility = collapsed ? "hidden" : ""
      accessory.style.opacity = collapsed ? "0" : ""
      accessory.style.pointerEvents = collapsed ? "none" : ""
    }
    button.setAttribute("aria-expanded", (!collapsed).toString())

    icon.classList.remove(...EXPANDED_ICON_CLASSES, ...COLLAPSED_ICON_CLASSES)
    icon.classList.add(...(collapsed ? COLLAPSED_ICON_CLASSES : EXPANDED_ICON_CLASSES))
  }

  #isCollapsed(section) {
    const content = section.querySelector('[data-role="section-content"]')
    return content ? content.classList.contains("hidden") : false
  }

  #persistSectionState(sectionId, collapsed) {
    this.savedState[sectionId] = collapsed

    if (!this.hasStorageKeyValue) return

    try {
      localStorage.setItem(this.storageKeyValue, JSON.stringify(this.savedState))
    } catch {
      // Ignore write errors (private mode/quota); UI should still work.
    }
  }

  #readSavedState() {
    if (!this.hasStorageKeyValue) return {}

    try {
      const raw = localStorage.getItem(this.storageKeyValue)
      return raw ? JSON.parse(raw) : {}
    } catch {
      return {}
    }
  }
}
