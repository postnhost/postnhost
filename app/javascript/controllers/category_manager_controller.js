import { Controller } from "@hotwired/stimulus"
import { showElement, hideElement } from "../helpers/dom_helpers"

export default class extends Controller {
  static targets = ["selector", "addButton", "categoryList", "template"]

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

  addCategory(event) {
    const select = event.target
    const categoryId = select.value
    const categoryName = select.options[select.selectedIndex].text

    if (categoryId && !this.#isCategorySelected(categoryId)) {
      this.#createCategoryItem(categoryId, categoryName)
      this.hideSelector()
      this.#updateSelectorOptions()
      this.#updateAddButtonVisibility()
      this.#markFormAsChanged()
    }

    select.value = ""
  }

  removeCategory(event) {
    const categoryItem = event.target.closest("[data-category-id]")
    if (categoryItem) {
      categoryItem.remove()
      this.#updateSelectorOptions()
      this.#updateAddButtonVisibility()
      this.#markFormAsChanged()
    }
  }

  #createCategoryItem(categoryId, categoryName) {
    const template = this.templateTarget.content.cloneNode(true)
    const categoryItem = template.querySelector("[data-category-id]")
    const nameSpan = template.querySelector("[data-category-name]")
    const hiddenInput = template.querySelector("input[type='hidden']")

    categoryItem.dataset.categoryId = categoryId
    nameSpan.textContent = categoryName
    hiddenInput.value = categoryId

    this.categoryListTarget.appendChild(template)
  }

  #isCategorySelected(categoryId) {
    return this.categoryListTarget.querySelector(`[data-category-id="${categoryId}"]`) !== null
  }

  #updateAddButtonVisibility() {
    const select = this.selectorTarget.querySelector("select")
    const hasAvailableOptions = Array.from(select.options).some(option =>
      option.value && !this.#isCategorySelected(option.value)
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
      if (option.value && this.#isCategorySelected(option.value)) {
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
