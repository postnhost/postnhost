import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["metaSidebar", "actionsSidebar"]

  toggleMeta() {
    if (!this.hasMetaSidebarTarget) return
    this.#toggle(this.metaSidebarTarget, this.hasActionsSidebarTarget ? this.actionsSidebarTarget : null)
  }

  toggleActions() {
    if (!this.hasActionsSidebarTarget) return
    this.#toggle(this.actionsSidebarTarget, this.hasMetaSidebarTarget ? this.metaSidebarTarget : null)
  }

  closeMeta() {
    if (!this.hasMetaSidebarTarget) return
    this.#hide(this.metaSidebarTarget)
  }

  closeActions() {
    if (!this.hasActionsSidebarTarget) return
    this.#hide(this.actionsSidebarTarget)
  }

  #toggle(target, otherTarget) {
    const shouldOpen = target.classList.contains("hidden")
    target.classList.toggle("hidden", !shouldOpen)

    if (otherTarget) this.#hide(otherTarget)
  }

  #hide(target) {
    target.classList.add("hidden")
  }
}
