import { Controller } from "@hotwired/stimulus"

const ENABLED_PRIMARY_CLASSES = ['bg-green-600', 'text-white', 'hover:bg-green-700', 'focus:ring-green-600']
const DISABLED_CLASSES = ['bg-gray-200', 'text-gray-500', 'border-gray-200', 'hover:bg-gray-200', 'cursor-not-allowed', 'pointer-events-none']

export default class extends Controller {
  static targets = ["titleField", "publishButton"]

  connect() {
    this.sync()
  }

  sync() {
    const canPublish = this.#titlePresent
    this.publishButtonTargets.forEach(button => this.#setButtonState(button, canPublish))
  }

  publishButtonTargetConnected(button) {
    this.#setButtonState(button, this.#titlePresent)
  }

  prevent(event) {
    if (this.#titlePresent) return

    event.preventDefault()
    event.stopPropagation()
  }

  get #titlePresent() {
    return this.hasTitleFieldTarget && this.titleFieldTarget.value.trim().length > 0
  }

  #setButtonState(button, enabled) {
    if (enabled) {
      button.removeAttribute('aria-disabled')
      button.removeAttribute('tabindex')
      button.classList.remove(...DISABLED_CLASSES)
      button.classList.add(...ENABLED_PRIMARY_CLASSES)
      return
    }

    button.setAttribute('aria-disabled', 'true')
    button.setAttribute('tabindex', '-1')
    button.classList.remove(...ENABLED_PRIMARY_CLASSES)
    button.classList.add(...DISABLED_CLASSES)
  }
}
