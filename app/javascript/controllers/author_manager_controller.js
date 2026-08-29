import { Controller } from "@hotwired/stimulus"
import { showElement, hideElement } from "../helpers/dom_helpers"

export default class extends Controller {
  static targets = ["selector", "addButton", "authorList", "template"]

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

  addAuthor(event) {
    const select = event.target
    const authorId = select.value
    const authorName = select.options[select.selectedIndex].text

    if (authorId && !this.#isAuthorSelected(authorId)) {
      this.#createAuthorItem(authorId, authorName)
      this.hideSelector()
      this.#updateSelectorOptions()
      this.#updateAddButtonVisibility()
      this.#markFormAsChanged()
    }

    select.value = ""
  }

  removeAuthor(event) {
    const authorItem = event.target.closest("[data-author-id]")
    if (authorItem) {
      authorItem.remove()
      this.#updateSelectorOptions()
      this.#updateAddButtonVisibility()
      this.#markFormAsChanged()
    }
  }

  #createAuthorItem(authorId, authorName) {
    const template = this.templateTarget.content.cloneNode(true)
    const authorItem = template.querySelector("[data-author-id]")
    const nameSpan = template.querySelector("[data-author-name]")
    const hiddenInput = template.querySelector("input[type='hidden']")

    authorItem.dataset.authorId = authorId
    nameSpan.textContent = authorName
    hiddenInput.value = authorId

    this.authorListTarget.appendChild(template)
  }

  #isAuthorSelected(authorId) {
    return this.authorListTarget.querySelector(`[data-author-id="${authorId}"]`) !== null
  }

  #updateAddButtonVisibility() {
    const select = this.selectorTarget.querySelector("select")
    const hasAvailableOptions = Array.from(select.options).some(option =>
      option.value && !this.#isAuthorSelected(option.value)
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
      if (option.value && this.#isAuthorSelected(option.value)) {
        option.style.display = "none"
      } else {
        option.style.display = ""
      }
    })
  }

  #markFormAsChanged() {
    const autoSaveRoot = this.element.closest('[data-controller*="auto-save"]')
    const autoSaveController = this.application.getControllerForElementAndIdentifier(autoSaveRoot, "auto-save")
    autoSaveController.markAsChanged()
  }
}
