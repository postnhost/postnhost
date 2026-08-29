import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input"]

  connect() {
    this.inputTargets.forEach((input) => {
      input.addEventListener("change", this.#handleFileChange)
    })
  }

  disconnect() {
    this.inputTargets.forEach((input) => {
      input.removeEventListener("change", this.#handleFileChange)
    })
  }

  #handleFileChange = (event) => {
    if (event.target.files.length > 0) {
      this.formTarget.requestSubmit()
    }
  }
}
