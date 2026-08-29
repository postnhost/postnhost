import { Controller } from "@hotwired/stimulus"
import AutoSaveState from "../helpers/auto_save_state"
import { setSavedButton, setSavingButton, setUploadingButton, setErrorButton } from "../helpers/style_helpers"

const TEXT_INPUT_TYPES = ['text', 'email', 'url', 'tel', 'search']
const ERROR_RESET_DELAY = 3000
const UNSAVED_CHANGES_MESSAGE = 'You have unsaved changes. Are you sure you want to leave?'

export default class extends Controller {
  static targets = ["form", "titleField", "saveButton"]
  static values = {
    delay: { type: Number, default: 500 }
  }

  connect() {
    this.saveState = new AutoSaveState()
    this.uploadsInProgress = 0
    this.saveTimeout = null
    this.errorResetTimeout = null
    this.#setupEventListeners()
    this.#setupBeforeUnload()
    this.#setupKeyboardShortcut()
    this.#setupTurboInterceptor()
  }

  disconnect() {
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    if (this.errorResetTimeout) clearTimeout(this.errorResetTimeout)
    window.removeEventListener('beforeunload', this.#handleBeforeUnload)
    document.removeEventListener('keydown', this.#handleKeyboardShortcut)
    document.removeEventListener('turbo:before-visit', this.#handleTurboVisit)
  }

  markAsChanged() {
    this.saveState.markChanged()
    this.#updateSaveButton()
    this.#scheduleAutoSave()
  }

  save(event) {
    if (event) event.preventDefault()
    this.#performSave()
  }

  #setupEventListeners() {
    // Title field changes
    if (this.hasTitleFieldTarget) {
      this.titleFieldTarget.addEventListener('input', () => this.markAsChanged())
    }

    // External component events
    document.addEventListener('tiptap:content-changed', () => this.markAsChanged())
    document.addEventListener('cover-image-upload:upload-start', () => this.#startUploadState())
    document.addEventListener('cover-image-upload:upload-complete', () => this.markAsChanged())
    document.addEventListener('cover-image-upload:upload-complete', () => this.#finishUploadState())
    document.addEventListener('cover-image-upload:upload-failed', () => this.#finishUploadState())
    document.addEventListener('tiptap-editor:upload-start', () => this.#startUploadState())
    document.addEventListener('tiptap-editor:upload-complete', () => this.#finishUploadState())
    document.addEventListener('tiptap-editor:upload-failed', () => this.#finishUploadState())
    document.addEventListener('cover-image-upload:delete-complete', () => this.markAsChanged())

    // Form field changes
    this.formTarget.querySelectorAll('input, select, textarea').forEach(field => {
      if (this.#shouldListenToField(field)) {
        field.addEventListener(this.#getEventType(field), () => this.markAsChanged())
      }
    })
  }

  #shouldListenToField(field) {
    const isTipTapField = field.closest('.tiptap') || field.closest('[data-controller*="tiptap"]')
    return field !== this.titleFieldTarget && field.type !== 'file' && !isTipTapField
  }

  #getEventType(field) {
    const isTextInput = field.tagName === 'TEXTAREA' ||
      (field.tagName === 'INPUT' && TEXT_INPUT_TYPES.includes(field.type))
    return isTextInput ? 'input' : 'change'
  }

  #setupBeforeUnload() {
    window.addEventListener('beforeunload', this.#handleBeforeUnload)
  }

  #setupKeyboardShortcut() {
    document.addEventListener('keydown', this.#handleKeyboardShortcut)
  }

  #setupTurboInterceptor() {
    document.addEventListener('turbo:before-visit', this.#handleTurboVisit)
  }

  #handleBeforeUnload = (e) => {
    if (this.saveState.hasUnsavedChanges) {
      e.preventDefault()
      e.returnValue = UNSAVED_CHANGES_MESSAGE
      return e.returnValue
    }
  }

  #handleKeyboardShortcut = (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 's') {
      e.preventDefault()
      if (this.saveState.hasUnsavedChanges) this.save(e)
    }
  }

  #handleTurboVisit = (e) => {
    if (this.saveState.hasUnsavedChanges && !confirm(UNSAVED_CHANGES_MESSAGE)) {
      e.preventDefault()
    }
  }

  #scheduleAutoSave() {
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.saveTimeout = null
    if (this.saveState.isSaving || !this.saveState.hasUnsavedChanges) return

    this.saveTimeout = setTimeout(() => {
      this.saveTimeout = null
      this.#performSave()
    }, this.delayValue)
  }

  #updateSaveButton() {
    if (!this.hasSaveButtonTarget) return

    if (this.uploadsInProgress > 0) {
      this.#showUploading()
      return
    }

    if (this.saveState.isSaving) {
      this.#showSaving()
      return
    }

    if (this.saveState.hasUnsavedChanges) {
      setSavedButton(this.saveButtonTarget)
      this.saveButtonTarget.disabled = false
      this.saveButtonTarget.classList.remove('cursor-not-allowed')
      this.saveButtonTarget.classList.add('cursor-pointer')
      this.saveButtonTarget.textContent = 'Save Changes'
    } else {
      setSavedButton(this.saveButtonTarget)
      this.saveButtonTarget.textContent = 'Saved'
    }
  }

  async #performSave() {
    const savingGeneration = this.saveState.beginSave()
    if (savingGeneration === null) return

    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.saveTimeout = null
    this.#showSaving()
    let saveSucceeded = false

    try {
      const formData = new FormData(this.formTarget)
      const response = await fetch(this.formTarget.action, {
        method: this.formTarget.method || 'POST',
        body: formData,
        headers: {
          'Accept': 'text/vnd.turbo-stream.html, application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
        }
      })

      if (response.ok) {
        const contentType = response.headers.get('content-type')
        if (contentType?.includes('turbo-stream')) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        }

        this.saveState.completeSave(savingGeneration)
        saveSucceeded = true
      } else {
        throw new Error(`HTTP ${response.status}`)
      }
    } catch (error) {
      if (this.saveState.isSaving) this.saveState.failSave(savingGeneration)
      console.error('Save failed:', error)
      this.#showError()
    } finally {
      if (saveSucceeded) this.#showSaved()
      if (this.saveState.hasChangesAfter(savingGeneration)) this.#scheduleAutoSave()
    }
  }

  #showSaving() {
    if (!this.hasSaveButtonTarget) return
    this.#clearErrorReset()
    setSavingButton(this.saveButtonTarget)
    this.saveButtonTarget.textContent = 'Saving...'
  }

  #showUploading() {
    if (!this.hasSaveButtonTarget) return
    setUploadingButton(this.saveButtonTarget)
    this.saveButtonTarget.innerHTML = `
      <span class="inline-flex items-center justify-center">
        <span class="inline-block h-3 w-3 mr-2 rounded-full border-2 border-current border-t-transparent animate-spin"></span>
        Uploading...
      </span>
    `
  }

  #startUploadState() {
    this.uploadsInProgress += 1
    this.#showUploading()
  }

  #finishUploadState() {
    this.uploadsInProgress = Math.max(0, this.uploadsInProgress - 1)
    if (this.uploadsInProgress === 0) this.#updateSaveButton()
  }

  #showSaved() {
    if (!this.hasSaveButtonTarget) return
    this.#updateSaveButton()
  }

  #showError() {
    if (!this.hasSaveButtonTarget) return

    this.#clearErrorReset()
    setErrorButton(this.saveButtonTarget)
    this.saveButtonTarget.textContent = 'Save Failed'

    this.errorResetTimeout = setTimeout(() => {
      this.errorResetTimeout = null
      this.#updateSaveButton()
    }, ERROR_RESET_DELAY)
  }

  #clearErrorReset() {
    if (!this.errorResetTimeout) return

    clearTimeout(this.errorResetTimeout)
    this.errorResetTimeout = null
  }
}
