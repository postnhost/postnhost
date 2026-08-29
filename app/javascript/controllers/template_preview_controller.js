import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["iframe", "status"]
  static values = { baseUrl: String }

  update(event) {
    if (!event.target.checked) return

    const previewUrl = new URL(this.baseUrlValue, window.location.origin)
    previewUrl.searchParams.set("preview_template", event.target.value)

    if (this.iframeTarget.src === previewUrl.toString()) return

    this.#showLoading()
    this.iframeTarget.src = previewUrl.toString()
  }

  loaded() {
    this.#hideLoading()
  }

  #showLoading() {
    if (!this.hasStatusTarget) return

    this.statusTarget.classList.remove("hidden")
  }

  #hideLoading() {
    if (!this.hasStatusTarget) return

    this.statusTarget.classList.add("hidden")
  }
}
