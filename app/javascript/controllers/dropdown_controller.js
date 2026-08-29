import { Controller } from "@hotwired/stimulus"
import { toggleElement, hideElement } from "../helpers/dom_helpers"

export default class extends Controller {
  static targets = ["menu", "chevron"]

  connect() {
    document.addEventListener("click", this.#handleClickOutside)
    this.#syncChevron()
  }

  disconnect() {
    document.removeEventListener("click", this.#handleClickOutside)
  }

  toggle() {
    toggleElement(this.menuTarget)
    this.#syncChevron()
  }

  close() {
    hideElement(this.menuTarget)
    this.#syncChevron()
  }

  #syncChevron() {
    if (!this.hasChevronTarget) return

    const isOpen = !this.menuTarget.classList.contains("hidden")
    this.chevronTarget.classList.toggle("rotate-180", isOpen)
  }

  #handleClickOutside = (event) => {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
