import { Controller } from "@hotwired/stimulus"
import { toggleElement, hideElement } from "../helpers/dom_helpers"

export default class extends Controller {
  connect() {
    const menu = document.getElementById('menu')

    if (!menu) {
      const icon = this.element.querySelector('svg[data-action*="burger#toggleMenu"]')
      if (icon) hideElement(icon)
    }
  }

  toggleMenu() {
    const menu = document.getElementById('menu')
    if (menu) {
      toggleElement(menu)
    }
  }
}
