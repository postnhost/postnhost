import { Controller } from "@hotwired/stimulus"
import { showElement, hideElement } from "../helpers/dom_helpers"

export default class extends Controller {
  static targets = ["selector", "addButton", "suggestionList", "template"]

  connect() {
    this.#updateAddButtonVisibility()
  }

  showSelector() {
    this.#updateSelectorOptions()
    showElement(this.selectorTarget)
    hideElement(this.addButtonTarget)
  }

  hideSelector() {
    hideElement(this.selectorTarget)
    showElement(this.addButtonTarget)
  }

  addSuggestion(event) {
    const select = event.target
    const suggestionId = select.value
    const suggestionName = select.options[select.selectedIndex].text

    if (suggestionId && !this.#isSuggestionSelected(suggestionId)) {
      this.#createSuggestionItem(suggestionId, suggestionName)
      this.hideSelector()
      this.#updateSelectorOptions()
      this.#updateAddButtonVisibility()
      this.#markFormAsChanged()
    }

    select.value = ""
  }

  removeSuggestion(event) {
    const suggestionItem = event.target.closest("[data-suggestion-id]")
    if (suggestionItem) {
      suggestionItem.remove()
      this.#updateSelectorOptions()
      this.#updateAddButtonVisibility()
      this.#markFormAsChanged()
    }
  }

  #createSuggestionItem(suggestionId, suggestionName) {
    const template = this.templateTarget.content.cloneNode(true)
    const suggestionItem = template.querySelector("[data-suggestion-id]")
    const nameSpan = template.querySelector("[data-suggestion-name]")
    const hiddenInput = template.querySelector("input[type='hidden']")

    suggestionItem.dataset.suggestionId = suggestionId
    nameSpan.textContent = suggestionName
    hiddenInput.value = suggestionId

    this.suggestionListTarget.appendChild(template)
  }

  #isSuggestionSelected(suggestionId) {
    return this.suggestionListTarget.querySelector(`[data-suggestion-id="${suggestionId}"]`) !== null
  }

  #updateAddButtonVisibility() {
    const select = this.selectorTarget.querySelector("select")
    const hasAvailableOptions = Array.from(select.options).some(option =>
      option.value && !this.#isSuggestionSelected(option.value)
    )

    if (hasAvailableOptions) {
      showElement(this.addButtonTarget)
    } else {
      hideElement(this.addButtonTarget)
    }
  }

  #updateSelectorOptions() {
    const select = this.selectorTarget.querySelector("select")
    const options = Array.from(select.options)

    options.forEach(option => {
      if (option.value && this.#isSuggestionSelected(option.value)) {
        option.style.display = "none"
      } else {
        option.style.display = ""
      }
    })
  }

  #markFormAsChanged() {
    const autoSaveRoot = this.element.closest('[data-controller*="auto-save"]')
    const autoSaveController = this.application.getControllerForElementAndIdentifier(
      autoSaveRoot,
      'auto-save'
    )
    autoSaveController.markAsChanged()
  }
}
