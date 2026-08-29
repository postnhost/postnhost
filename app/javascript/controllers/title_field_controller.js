import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  preventNewLine(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.#focusEditor()
    }
  }

  #focusEditor() {
    const editor = document.querySelector(".ProseMirror")
    if (editor) {
      editor.focus()
    }
  }
}
