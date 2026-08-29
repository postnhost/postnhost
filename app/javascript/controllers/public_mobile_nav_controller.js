import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.close()
  }

  toggle() {
    const isHidden = this.panelTarget.classList.contains("hidden")
    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }
}
