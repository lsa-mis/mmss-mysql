import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    storageKey: String,
    saveInterval: { type: Number, default: 30000 }, // Default: 30 seconds
    // "local" (default) = localStorage, survives browser close. "session" = sessionStorage, cleared when tab closes.
    storageType: { type: String, default: 'local' },
    // Max age in ms before restored data is considered stale (localStorage only). e.g. 86400000 = 24 hours. Unset = no limit.
    maxAgeMs: Number
  }

  connect() {
    // Get the form element (controller might be on form or wrapper)
    this.form = this.element.tagName === 'FORM' ? this.element : this.element.closest('form')
    this.hasRestoredData = false
    
    if (!this.form) {
      console.warn('Autosave controller: No form found')
      return
    }

    if (!this.hasStorageKeyValue) {
      // Generate a storage key based on form action if not provided
      if (this.form.action) {
        // Use form action + pathname as storage key
        const url = new URL(this.form.action, window.location.origin)
        this.storageKeyValue = `autosave_${url.pathname}`
      } else {
        // Fallback to page pathname
        this.storageKeyValue = `autosave_${window.location.pathname}`
      }
    }

    // Restore saved data on load
    this.restoreFormData()

    // Ensure handler references exist and remove any existing listeners
    if (this.onInput) {
      this.form.removeEventListener('input', this.onInput, true)
    }
    if (this.onChange) {
      this.form.removeEventListener('change', this.onChange, true)
    }
    if (this.onSubmit) {
      this.form.removeEventListener('submit', this.onSubmit)
    }
    if (this.onBeforeUnload) {
      window.removeEventListener('beforeunload', this.onBeforeUnload)
    }

    // Create stable handler references
    this.onInput = this.onInput || (() => this.debouncedSave())
    this.onChange = this.onChange || (() => this.debouncedSave())
    this.onSubmit =
      this.onSubmit ||
      (() => {
        // Clear after a short delay to allow form submission to complete
        setTimeout(() => {
          this.clearSavedData()
          this.hideRestoreMessage()
        }, 1000)
      })
    this.onBeforeUnload =
      this.onBeforeUnload ||
      (() => {
        this.saveFormData()
      })

    // Auto-save on input/change events (these bubble up from inputs to form)
    this.form.addEventListener('input', this.onInput, true)
    this.form.addEventListener('change', this.onChange, true)

    // Auto-save periodically (avoid duplicate intervals on reconnect)
    if (this.saveIntervalId) {
      clearInterval(this.saveIntervalId)
    }
    this.saveIntervalId = setInterval(() => {
      this.saveFormData()
    }, this.saveIntervalValue)

    // Clear saved data on successful form submission
    this.form.addEventListener('submit', this.onSubmit)

    // Handle beforeunload to save data before page unload
    window.addEventListener('beforeunload', this.onBeforeUnload)

    // Show restore message if data was restored
    if (this.hasRestoredData) {
      this.showRestoreMessage()
    }
  }

  disconnect() {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
      this.saveTimeout = null
    }
    if (this.saveIntervalId) {
      clearInterval(this.saveIntervalId)
      this.saveIntervalId = null
    }
    if (this.form) {
      if (this.onInput) {
        this.form.removeEventListener('input', this.onInput, true)
      }
      if (this.onChange) {
        this.form.removeEventListener('change', this.onChange, true)
      }
      if (this.onSubmit) {
        this.form.removeEventListener('submit', this.onSubmit)
      }
    }
    if (this.onBeforeUnload) {
      window.removeEventListener('beforeunload', this.onBeforeUnload)
    }
  }

  // Debounce save operations to avoid excessive localStorage writes
  debouncedSave() {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }
    this.saveTimeout = setTimeout(() => {
      this.saveFormData()
    }, 1000) // Wait 1 second after last change
  }

  // Field names that must never be persisted (security/PII, Rails internals)
  static DENYLIST_KEYS = [
    'authenticity_token', 'utf8', 'commit', '_method',
    'password', 'password_confirmation', 'current_password',
    'token', 'api_key', 'secret', 'csrf_token'
  ]

  static isDenylisted(key) {
    const lower = key.toLowerCase()
    return this.DENYLIST_KEYS.some(d => lower === d || lower.includes('password') || lower.includes('secret'))
  }

  get storage() {
    return (this.storageTypeValue === 'session') ? sessionStorage : localStorage
  }

  saveFormData() {
    try {
      if (!this.form) return

      const formData = new FormData(this.form)
      const data = {}

      // Save form fields except denylisted and file inputs (can't be serialized)
      for (const [key, value] of formData.entries()) {
        if (this.constructor.isDenylisted(key)) continue

        const input = this.form.querySelector(`[name="${key}"]`)
        if (input && input.type === 'file') {
          // For file inputs, save metadata only
          if (input.files && input.files.length > 0) {
            data[`${key}_filename`] = input.files[0].name
            data[`${key}_size`] = input.files[0].size
            // Note: Can't save actual file, user will need to re-select
          }
        } else {
          // Handle checkboxes and radio buttons
          if (input && (input.type === 'checkbox' || input.type === 'radio')) {
            // Collect all checked values for checkboxes
            const checkboxes = this.form.querySelectorAll(`[name="${key}"]:checked`)
            if (checkboxes.length > 1) {
              data[key] = Array.from(checkboxes).map(cb => cb.value)
            } else {
              data[key] = value
            }
          } else {
            data[key] = value
          }
        }
      }

      // Save timestamp
      data._saved_at = new Date().toISOString()

      this.storage.setItem(this.storageKeyValue, JSON.stringify(data))
    } catch (error) {
      console.warn('Autosave failed:', error)
    }
  }

  restoreFormData() {
    try {
      if (!this.form) return
      
      const savedData = this.storage.getItem(this.storageKeyValue)
      if (!savedData) return

      const data = JSON.parse(savedData)
      if (this.hasMaxAgeMsValue && data._saved_at) {
        const age = Date.now() - new Date(data._saved_at).getTime()
        if (age > this.maxAgeMsValue) return // Data too old, don't restore
      }

      let hasRestored = false

      // Restore form fields
      for (const [key, value] of Object.entries(data)) {
        if (key.startsWith('_')) continue // Skip metadata
        if (this.constructor.isDenylisted(key)) continue

        const input = this.form.querySelector(`[name="${key}"]`)
        if (!input) continue

        // Handle checkboxes and radio buttons
        if (input.type === 'checkbox' || input.type === 'radio') {
          if (Array.isArray(value)) {
            // Multiple checkboxes
            value.forEach(val => {
              const checkbox = this.form.querySelector(`[name="${key}"][value="${val}"]`)
              if (checkbox) {
                checkbox.checked = true
                hasRestored = true
              }
            })
          } else {
            // Single checkbox or radio
            const checkbox = this.form.querySelector(`[name="${key}"][value="${value}"]`)
            if (checkbox) {
              checkbox.checked = true
              hasRestored = true
            } else if (input.type === 'checkbox' && value) {
              input.checked = true
              hasRestored = true
            }
          }
        } else if (input.type === 'file') {
          // For file inputs, show a message about re-selecting
          const filename = data[`${key}_filename`]
          if (filename) {
            this.showFileRestoreWarning(input, filename)
          }
        } else {
          // Text inputs, selects, textareas
          input.value = value
          hasRestored = true
          
          // Trigger change event for any dependent JavaScript
          input.dispatchEvent(new Event('change', { bubbles: true }))
        }
      }

      if (hasRestored) {
        this.hasRestoredData = true
      }
    } catch (error) {
      console.warn('Autosave restore failed:', error)
    }
  }

  showFileRestoreWarning(input, filename) {
    // Create a warning message next to the file input (use textContent to avoid XSS from untrusted filename)
    const warningId = `file-warning-${input.name}`
    if (document.getElementById(warningId)) return // Already shown

    const warning = document.createElement('div')
    warning.id = warningId
    warning.className = 'text-yellow-600 text-sm mt-1'
    const noteSpan = document.createElement('span')
    noteSpan.className = 'font-semibold'
    noteSpan.textContent = 'Note: '
    warning.appendChild(noteSpan)
    warning.appendChild(document.createTextNode(`Previously selected file "${filename}" could not be restored. Please select your file again.`))
    
    input.parentNode.insertBefore(warning, input.nextSibling)
  }

  clearSavedData() {
    try {
      this.storage.removeItem(this.storageKeyValue)
      // Clear any file warnings
      const warnings = document.querySelectorAll('[id^="file-warning-"]')
      warnings.forEach(warning => warning.remove())
    } catch (error) {
      console.warn('Autosave clear failed:', error)
    }
  }

  showRestoreMessage() {
    // Show a banner that data was restored
    const messageId = 'autosave-restore-message'
    if (document.getElementById(messageId)) return

    const message = document.createElement('div')
    message.id = messageId
    message.className = 'bg-blue-100 border-l-4 border-blue-500 text-blue-700 p-4 mb-4'
    message.innerHTML = `
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
          </svg>
          <span>Your previously entered form data has been restored. Please review and continue.</span>
        </div>
        <button onclick="this.parentElement.parentElement.remove()" class="text-blue-700 hover:text-blue-900 ml-4">
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
          </svg>
        </button>
      </div>
    `

    if (this.form) {
      this.form.insertBefore(message, this.form.firstChild)
    }
  }

  hideRestoreMessage() {
    const message = document.getElementById('autosave-restore-message')
    if (message) {
      message.remove()
    }
  }
}
