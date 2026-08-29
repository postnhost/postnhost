import { Controller } from "@hotwired/stimulus"
import { setPrimaryButton, setDisabledButton } from "../helpers/style_helpers"

const DEFAULT_TEXT = "Select languages to translate"

export default class extends Controller {
  static targets = ["checkbox", "submitButton"]

  toggleCheckbox(event) {
    this.#updateSubmitButton()
  }

  selectAll() {
    this.checkboxTargets.forEach(checkbox => checkbox.checked = true)
    this.#updateSubmitButton()
  }

  selectNone() {
    this.checkboxTargets.forEach(checkbox => checkbox.checked = false)
    this.#updateSubmitButton()
  }

  #updateSubmitButton() {
    const checkedCount = this.#checkedCount

    if (checkedCount > 0) {
      setPrimaryButton(this.submitButtonTarget)
      this.submitButtonTarget.textContent = `Translate to ${checkedCount} language${checkedCount > 1 ? 's' : ''}`
    } else {
      this.#resetSubmitButton()
    }
  }

  #resetSubmitButton() {
    setDisabledButton(this.submitButtonTarget)
    this.submitButtonTarget.textContent = DEFAULT_TEXT
  }

  get #checkedCount() {
    return this.checkboxTargets.filter(cb => cb.checked).length
  }
}
