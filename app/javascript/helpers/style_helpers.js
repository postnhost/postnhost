// Centralized Tailwind CSS class definitions for consistent styling across the app
// Following DRY principle: define once, use everywhere

// Button State Classes
export const BUTTON_STATES = {
  primary: ['bg-gray-900', 'text-white', 'border-gray-900', 'hover:bg-gray-800', 'cursor-pointer'],
  secondary: ['bg-white', 'border-gray-300', 'text-gray-700', 'hover:bg-gray-50', 'cursor-pointer'],
  disabled: ['bg-gray-300', 'text-gray-500', 'cursor-not-allowed'],
  saved: ['bg-white', 'border-gray-300', 'text-gray-700', 'hover:bg-gray-50', 'opacity-50', 'cursor-not-allowed'],
  saving: ['opacity-75', 'cursor-not-allowed'],
  uploading: ['bg-purple-100', 'text-purple-800', 'border-purple-200', 'cursor-not-allowed'],
  error: ['bg-red-600', 'text-white', 'border-red-600', 'hover:bg-red-700']
}

// Editor Toolbar States
export const EDITOR_STATES = {
  active: ['bg-gray-900', 'text-white'],
  inactive: ['text-gray-500', 'hover:text-gray-900', 'hover:bg-gray-100'],
  disabled: ['opacity-50', 'cursor-not-allowed'],
  dragOver: ['border-blue-500', 'border-2', 'border-dashed', 'bg-blue-50']
}

// Animation Classes
export const ANIMATION_CLASSES = {
  fadeIn: ['transition-all', 'duration-300', 'ease-out', 'scale-100', 'opacity-100'],
  fadeOut: ['transform', 'scale-95', 'opacity-0'],
  initial: ['transform', 'scale-95', 'opacity-0']
}

// Drag & Drop States
export const DRAG_STATES = {
  over: ['border-gray-400', 'bg-gray-50'],
  leave: []
}

// Utility Functions

/**
 * Apply multiple CSS classes to an element
 * @param {HTMLElement} element - Target element
 * @param {string[]} classes - Array of class names to add
 */
export function applyClasses(element, classes) {
  if (!element || !Array.isArray(classes)) return
  element.classList.add(...classes)
}

/**
 * Remove multiple CSS classes from an element
 * @param {HTMLElement} element - Target element
 * @param {string[]} classes - Array of class names to remove
 */
export function removeClasses(element, classes) {
  if (!element || !Array.isArray(classes)) return
  element.classList.remove(...classes)
}

/**
 * Toggle classes: remove old set, add new set
 * @param {HTMLElement} element - Target element
 * @param {string[]} addClasses - Classes to add
 * @param {string[]} removeClasses - Classes to remove
 */
export function toggleClasses(element, addClasses, removeClasses) {
  if (!element) return

  if (Array.isArray(removeClasses) && removeClasses.length > 0) {
    element.classList.remove(...removeClasses)
  }

  if (Array.isArray(addClasses) && addClasses.length > 0) {
    element.classList.add(...addClasses)
  }
}

/**
 * Set button to primary state
 * @param {HTMLElement} button - Button element
 */
export function setPrimaryButton(button) {
  if (!button) return
  toggleClasses(button, BUTTON_STATES.primary, [
    ...BUTTON_STATES.secondary,
    ...BUTTON_STATES.disabled,
    ...BUTTON_STATES.saved,
    ...BUTTON_STATES.saving,
    ...BUTTON_STATES.uploading,
    ...BUTTON_STATES.error
  ])
  button.disabled = false
}

/**
 * Set button to disabled state
 * @param {HTMLElement} button - Button element
 */
export function setDisabledButton(button) {
  if (!button) return
  toggleClasses(button, BUTTON_STATES.disabled, [
    ...BUTTON_STATES.primary,
    ...BUTTON_STATES.secondary,
    ...BUTTON_STATES.saved,
    ...BUTTON_STATES.saving,
    ...BUTTON_STATES.uploading,
    ...BUTTON_STATES.error
  ])
  button.disabled = true
}

/**
 * Set button to error state
 * @param {HTMLElement} button - Button element
 */
export function setErrorButton(button) {
  if (!button) return
  toggleClasses(button, BUTTON_STATES.error, [
    ...BUTTON_STATES.primary,
    ...BUTTON_STATES.secondary,
    ...BUTTON_STATES.saved,
    ...BUTTON_STATES.saving,
    ...BUTTON_STATES.uploading,
    ...BUTTON_STATES.disabled
  ])
  button.disabled = false
}

/**
 * Set button to saved state
 * @param {HTMLElement} button - Button element
 */
export function setSavedButton(button) {
  if (!button) return
  toggleClasses(button, BUTTON_STATES.saved, [
    ...BUTTON_STATES.primary,
    ...BUTTON_STATES.saving,
    ...BUTTON_STATES.uploading,
    ...BUTTON_STATES.error
  ])
  button.disabled = true
}

/**
 * Set button to saving state
 * @param {HTMLElement} button - Button element
 */
export function setSavingButton(button) {
  if (!button) return
  removeClasses(button, BUTTON_STATES.uploading)
  applyClasses(button, BUTTON_STATES.saving)
  removeClasses(button, ['cursor-pointer'])
  button.disabled = true
}

/**
 * Set button to uploading state
 * @param {HTMLElement} button - Button element
 */
export function setUploadingButton(button) {
  if (!button) return
  toggleClasses(button, BUTTON_STATES.uploading, [
    ...BUTTON_STATES.primary,
    ...BUTTON_STATES.secondary,
    ...BUTTON_STATES.saved,
    ...BUTTON_STATES.error
  ])
  applyClasses(button, BUTTON_STATES.saving)
  button.disabled = true
}
