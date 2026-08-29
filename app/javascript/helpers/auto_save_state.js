export default class AutoSaveState {
  constructor() {
    this.changeGeneration = 0
    this.savedGeneration = 0
    this.savingGeneration = null
  }

  get hasUnsavedChanges() {
    return this.changeGeneration > this.savedGeneration
  }

  get isSaving() {
    return this.savingGeneration !== null
  }

  markChanged() {
    this.changeGeneration += 1
  }

  beginSave() {
    if (this.isSaving || !this.hasUnsavedChanges) return null

    this.savingGeneration = this.changeGeneration
    return this.savingGeneration
  }

  completeSave(generation) {
    this.#assertActiveSave(generation)
    this.savedGeneration = Math.max(this.savedGeneration, generation)
    this.savingGeneration = null
  }

  failSave(generation) {
    this.#assertActiveSave(generation)
    this.savingGeneration = null
  }

  hasChangesAfter(generation) {
    return this.changeGeneration > generation
  }

  #assertActiveSave(generation) {
    if (generation !== this.savingGeneration) {
      throw new Error(`Expected active save generation ${this.savingGeneration}, received ${generation}`)
    }
  }
}
