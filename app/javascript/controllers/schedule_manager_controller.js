import { Controller } from "@hotwired/stimulus"
import { showElement, hideElement } from "../helpers/dom_helpers"

export default class extends Controller {
  static targets = ["selector", "addButton", "scheduledSummary", "input"]

  connect() {
    this.#syncInitialState()
  }

  showSelector() {
    if (this.hasSelectorTarget) {
      showElement(this.selectorTarget)
    }
    this.#hideAddButtons()
    this.#hideScheduledSummary()
  }

  hideSelector() {
    if (this.hasSelectorTarget) {
      hideElement(this.selectorTarget)
    }
    this.#showAddButtons()
    this.#toggleScheduledSummary()
  }

  clearSchedule() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
    }
    this.#markFormAsChanged()
    if (this.hasSelectorTarget) {
      hideElement(this.selectorTarget)
    }
    this.#showAddButtons()
    this.#hideScheduledSummary()
  }

  markChanged() {
    this.#markFormAsChanged()
  }

  #syncInitialState() {
    if (this.hasScheduledSummaryTarget) {
      this.#hideAddButtons()
      if (this.hasSelectorTarget) {
        hideElement(this.selectorTarget)
      }
    } else {
      this.#showAddButtons()
      if (this.hasSelectorTarget) {
        hideElement(this.selectorTarget)
      }
    }
  }

  #toggleScheduledSummary() {
    if (this.hasScheduledSummaryTarget) {
      showElement(this.scheduledSummaryTarget)
    }
  }

  #hideScheduledSummary() {
    if (this.hasScheduledSummaryTarget) {
      hideElement(this.scheduledSummaryTarget)
    }
  }

  #showAddButtons() {
    this.addButtonTargets.forEach(button => showElement(button))
  }

  #hideAddButtons() {
    this.addButtonTargets.forEach(button => hideElement(button))
  }

  #markFormAsChanged() {
    const autoSaveController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="auto-save"]'),
      'auto-save'
    )

    if (autoSaveController) {
      autoSaveController.markAsChanged()
    }
  }
}
