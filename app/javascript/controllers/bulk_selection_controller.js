import { Controller } from "@hotwired/stimulus"
import { showElement, hideElement } from "../helpers/dom_helpers"

export default class extends Controller {
  static targets = ["checkbox", "checkAll", "bulkActions", "selectedCount"]

  connect() {
    this.#uncheckAll()
  }

  toggleAll() {
    const checked = this.checkAllTarget.checked
    this.#selectableCheckboxTargets().forEach(checkbox => {
      checkbox.checked = checked
    })
    this.#updateBulkActions()
  }

  toggle() {
    this.#updateCheckAllState()
    this.#updateBulkActions()
  }

  #selectableCheckboxTargets() {
    return this.checkboxTargets.filter(cb => !cb.disabled)
  }

  #syncCheckAllEnabled() {
    const selectable = this.#selectableCheckboxTargets()
    this.checkAllTarget.disabled = selectable.length === 0
  }

  #updateCheckAllState() {
    const selectable = this.#selectableCheckboxTargets()
    if (selectable.length === 0) {
      this.checkAllTarget.checked = false
      this.checkAllTarget.indeterminate = false
      return
    }

    const allChecked = selectable.every(cb => cb.checked)
    const someChecked = selectable.some(cb => cb.checked)

    this.checkAllTarget.checked = allChecked
    this.checkAllTarget.indeterminate = someChecked && !allChecked
  }

  #updateBulkActions() {
    const selectedCount = this.#selectedCount

    if (selectedCount > 0) {
      showElement(this.bulkActionsTarget)
      if (this.hasSelectedCountTarget) {
        this.selectedCountTarget.textContent = selectedCount
      }
    } else {
      hideElement(this.bulkActionsTarget)
    }
  }

  #uncheckAll() {
    this.checkAllTarget.checked = false
    this.checkAllTarget.indeterminate = false
    this.#selectableCheckboxTargets().forEach(cb => {
      cb.checked = false
    })
    this.#syncCheckAllEnabled()
    this.#updateBulkActions()
  }

  get #selectedCount() {
    return this.#selectableCheckboxTargets().filter(cb => cb.checked).length
  }
}
