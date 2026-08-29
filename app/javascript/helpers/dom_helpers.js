// DOM manipulation utilities
// Follows KISS principle: simple, reusable DOM operations

/**
 * Show an element by removing 'hidden' class
 * @param {HTMLElement} element - Element to show
 */
export function showElement(element) {
  if (!element) return
  element.classList.remove('hidden')
}

/**
 * Hide an element by adding 'hidden' class
 * @param {HTMLElement} element - Element to hide
 */
export function hideElement(element) {
  if (!element) return
  element.classList.add('hidden')
}

/**
 * Toggle element visibility
 * @param {HTMLElement} element - Element to toggle
 */
export function toggleElement(element) {
  if (!element) return
  element.classList.toggle('hidden')
}

/**
 * Create a toast notification
 * @param {string} message - Message to display
 * @param {string} type - Type of toast: 'success', 'error', 'info', 'warning'
 * @param {number} duration - Duration in milliseconds (default: 5000)
 * @returns {HTMLElement} The created toast element
 */
export function createToast(message, type = 'error', duration = 5000) {
  const toastConfig = {
    success: {
      bg: 'bg-green-50',
      border: 'border-green-200',
      textColor: 'text-green-800',
      iconColor: 'text-green-600',
      icon: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    },
    error: {
      bg: 'bg-red-50',
      border: 'border-red-200',
      textColor: 'text-red-800',
      iconColor: 'text-red-600',
      icon: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    },
    info: {
      bg: 'bg-blue-50',
      border: 'border-blue-200',
      textColor: 'text-blue-800',
      iconColor: 'text-blue-600',
      icon: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    },
    warning: {
      bg: 'bg-yellow-50',
      border: 'border-yellow-200',
      textColor: 'text-yellow-800',
      iconColor: 'text-yellow-600',
      icon: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>'
    }
  }


  const config = toastConfig[type] || toastConfig.error

  const toast = document.createElement('div')
  toast.className = `fixed top-4 right-4 ${config.bg} border ${config.border} rounded-xl px-4 py-3 shadow-lg z-50`
  toast.innerHTML = `
    <div class="flex items-center">
      <svg class="w-5 h-5 ${config.iconColor} mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        ${config.icon}
      </svg>
      <span class="text-sm ${config.textColor}">${message}</span>
    </div>
  `

  document.body.appendChild(toast)

  setTimeout(() => {
    toast.remove()
  }, duration)

  return toast
}

/**
 * Safely remove an element from the DOM
 * @param {HTMLElement} element - Element to remove
 */
export function removeElement(element) {
  if (!element || !element.parentNode) return
  element.remove()
}

/**
 * Check if element exists in DOM
 * @param {HTMLElement} element - Element to check
 * @returns {boolean}
 */
export function elementExists(element) {
  return element && element.parentNode !== null
}
