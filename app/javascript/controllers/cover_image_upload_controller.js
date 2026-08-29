import { Controller } from "@hotwired/stimulus"
import { hideElement, showElement, createToast } from "../helpers/dom_helpers"
import { applyClasses, removeClasses, DRAG_STATES } from "../helpers/style_helpers"

const VALID_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic']
const MAX_FILE_SIZE = 25 * 1024 * 1024 // 25MB

export default class extends Controller {
  static targets = ["input", "uploadArea", "spinner", "placeholder", "preview", "previewImage", "altField", "uploadSection"]
  static values = {
    articleId: String,
    mountPath: { type: String, default: '' }
  }

  dragOver(event) {
    event.preventDefault()
    applyClasses(this.uploadAreaTarget, DRAG_STATES.over)
  }

  dragLeave(event) {
    event.preventDefault()
    removeClasses(this.uploadAreaTarget, DRAG_STATES.over)
  }

  drop(event) {
    event.preventDefault()
    removeClasses(this.uploadAreaTarget, DRAG_STATES.over)

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.#uploadImage(files[0])
    }
  }

  selectFile(event) {
    const files = event.target.files
    if (files.length > 0) {
      this.#uploadImage(files[0])
    }
  }

  triggerFileInput() {
    this.inputTarget.click()
  }

  removeImage() {
    const mountPath = this.mountPathValue === '/' ? '' : this.mountPathValue.replace(/\/$/, '')
    const deleteUrl = `${mountPath}/articles/${this.articleIdValue}/cover_image`

    fetch(deleteUrl, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
      }
    })
      .then(response => {
        if (response.ok) {
          this.#hidePreview()
          this.dispatch('delete-complete', { bubbles: true })
        } else {
          createToast('Failed to remove image', 'error')
        }
      })
      .catch(error => {
        console.error('Delete error:', error)
        createToast('Failed to remove image', 'error')
      })
  }

  #uploadImage(file) {
    if (!this.#validateFile(file)) return

    this.dispatch('upload-start', { bubbles: true })
    this.#showLoading()

    const formData = new FormData()
    formData.append('file', file)

    const mountPath = this.mountPathValue === '/' ? '' : this.mountPathValue.replace(/\/$/, '')
    const uploadUrl = `${mountPath}/articles/${this.articleIdValue}/cover_image`

    fetch(uploadUrl, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
      }
    })
      .then(response => response.json())
      .then(data => {
        if (data.url) {
          this.#showPreview(data.url)
          this.#hideLoading()
          this.dispatch('upload-complete', { bubbles: true })
        } else {
          createToast(data.error || 'Failed to upload image', 'error')
          this.#hideLoading()
          this.dispatch('upload-failed', { bubbles: true })
        }
      })
      .catch(error => {
        console.error('Upload error:', error)
        createToast('Failed to upload image', 'error')
        this.#hideLoading()
        this.dispatch('upload-failed', { bubbles: true })
      })
  }

  #validateFile(file) {
    if (!VALID_IMAGE_TYPES.includes(file.type)) {
      createToast('Please upload a valid image file (JPEG, PNG, GIF, WEBP, HEIC)', 'error')
      return false
    }

    if (file.size > MAX_FILE_SIZE) {
      createToast('Image size must be less than 25MB', 'error')
      return false
    }

    return true
  }

  #showPreview(imageUrl) {
    if (this.hasUploadSectionTarget) {
      hideElement(this.uploadSectionTarget)
    }

    if (this.hasPreviewImageTarget) {
      this.previewImageTarget.src = imageUrl
    }

    if (this.hasPreviewTarget) {
      showElement(this.previewTarget)
    }

    if (this.hasAltFieldTarget) {
      this.altFieldTarget.value = ''
    }
  }

  #hidePreview() {
    if (this.hasPreviewTarget) {
      hideElement(this.previewTarget)
    }

    if (this.hasUploadSectionTarget) {
      showElement(this.uploadSectionTarget)
    }

    if (this.hasInputTarget) {
      this.inputTarget.value = ''
    }
  }

  #showLoading() {
    hideElement(this.placeholderTarget)
    showElement(this.spinnerTarget)
  }

  #hideLoading() {
    hideElement(this.spinnerTarget)
    showElement(this.placeholderTarget)
  }
}
