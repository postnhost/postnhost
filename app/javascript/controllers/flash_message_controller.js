import { Controller } from "@hotwired/stimulus"
import { removeElement, elementExists } from "../helpers/dom_helpers"
import { applyClasses, toggleClasses, ANIMATION_CLASSES } from "../helpers/style_helpers"

const ANIMATION_DELAY = 50
const CLOSE_ANIMATION_DURATION = 300

export default class extends Controller {
  static targets = ["message"]

  connect() {
    applyClasses(this.messageTarget, ANIMATION_CLASSES.initial)

    void this.messageTarget.offsetWidth

    this.messageTarget.classList.add("transition-all", "duration-300", "ease-out")

    setTimeout(() => {
      toggleClasses(this.messageTarget, ANIMATION_CLASSES.fadeIn, ANIMATION_CLASSES.fadeOut)
    }, ANIMATION_DELAY)
  }

  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    const messageElement = this.hasMessageTarget ? this.messageTarget : this.element
    if (!messageElement) return

    applyClasses(messageElement, ANIMATION_CLASSES.fadeOut)

    setTimeout(() => {
      if (elementExists(messageElement)) {
        removeElement(messageElement)
      }
    }, CLOSE_ANIMATION_DURATION)
  }
}
