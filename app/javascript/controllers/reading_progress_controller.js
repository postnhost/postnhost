import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar"]

  #ticking = false

  connect() {
    this.#updateProgress()
    window.addEventListener("scroll", this.#handleScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.#handleScroll)
  }

  #handleScroll = () => {
    if (!this.#ticking) {
      this.#ticking = true
      requestAnimationFrame(() => {
        this.#updateProgress()
        this.#ticking = false
      })
    }
  }

  #updateProgress() {
    const article = document.querySelector("article")
    if (!article) return

    const articleBottom = article.offsetTop + article.offsetHeight
    const scrollTop = window.scrollY
    const scrollableDistance = articleBottom - window.innerHeight
    const progress = scrollableDistance > 0 ? (scrollTop / scrollableDistance) * 100 : 0

    this.barTarget.style.width = `${Math.max(0, Math.min(progress, 100))}%`
  }
}
