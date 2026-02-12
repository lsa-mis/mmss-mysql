import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["warning"]
  static values = {
    expiresAt: Number,
    warningMinutes: { type: Number, default: 5 }
  }

  connect() {
    if (!this.hasExpiresAtValue) {
      return // No expiry time set, skip timeout checking
    }

    // Check every 30 seconds for session expiry
    this.checkInterval = setInterval(() => {
      this.checkSessionExpiry()
    }, 30000) // 30 seconds

    // Also check immediately
    this.checkSessionExpiry()

    // Check before form submission - use a single delegated submit handler
    this.setupFormSubmissionWarning()
  }

  setupFormSubmissionWarning() {
    // Avoid attaching multiple listeners if connect() is called again
    if (!this.formSubmitHandler) {
      this.formSubmitHandler = this.handleFormSubmit.bind(this)
      document.addEventListener('submit', this.formSubmitHandler)
    }
  }

  handleFormSubmit(e) {
    if (this.isSessionAboutToExpire()) {
      const proceed = confirm(
        'Your session is about to expire. If you submit now, you may need to sign in again. Do you want to continue?'
      )
      if (!proceed) {
        e.preventDefault()
        return false
      }
    }
  }

  disconnect() {
    if (this.checkInterval) {
      clearInterval(this.checkInterval)
    }

    if (this.formSubmitHandler) {
      document.removeEventListener('submit', this.formSubmitHandler)
      this.formSubmitHandler = null
    }
  }

  checkSessionExpiry() {
    if (this.isSessionAboutToExpire()) {
      this.showWarning()
    } else {
      this.hideWarning()
    }
  }

  isSessionAboutToExpire() {
    if (!this.hasExpiresAtValue) {
      return false
    }

    const now = Math.floor(Date.now() / 1000) // Current time in seconds
    const warningThreshold = this.warningMinutesValue * 60 // Convert minutes to seconds
    const timeUntilExpiry = this.expiresAtValue - now

    return timeUntilExpiry > 0 && timeUntilExpiry <= warningThreshold
  }

  showWarning() {
    if (this.hasWarningTarget) {
      this.warningTarget.classList.remove('hidden')
    }
  }

  hideWarning() {
    if (this.hasWarningTarget) {
      this.warningTarget.classList.add('hidden')
    }
  }

  dismissWarning() {
    this.hideWarning()
  }
}
