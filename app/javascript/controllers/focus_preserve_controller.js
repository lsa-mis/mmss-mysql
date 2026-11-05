// Restores keyboard focus after Turbo Drive replaces the page from a filter or
// sort navigation (LRA-1522). Capture a stable id before navigation; on connect
// (new page), focus the matching control.
import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "mmss-admin-focus-preserve"

export default class extends Controller {
  connect() {
    this.restore()
  }

  // Sort header links and Clear filters. Only same-tab primary navigations
  // schedule restore — modified clicks open another tab/window and leave this page.
  capture(event) {
    if (this.modifiedClick(event)) return

    const id = event.currentTarget.dataset.focusPreserveId
    if (!id) return
    sessionStorage.setItem(STORAGE_KEY, id)
  }

  // Filter form submit (button click or Enter in a field).
  captureSubmit(event) {
    const id = event.submitter?.dataset?.focusPreserveId || "admin-filter-submit"
    sessionStorage.setItem(STORAGE_KEY, id)
  }

  restore() {
    // Cached preview connects first on revisit; leave the stored id untouched
    // so the final (non-preview) render can restore focus.
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    const id = sessionStorage.getItem(STORAGE_KEY)
    if (!id) return
    sessionStorage.removeItem(STORAGE_KEY)

    // Defer past Turbo/Stimulus settle so the replacement control exists and
    // wins any competing autofocus.
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.focusTimer = setTimeout(() => {
          this.focusTimer = null
          if (!this.element.isConnected) return
          const el = this.element.querySelector(`[data-focus-preserve-id="${CSS.escape(id)}"]`)
          if (el && typeof el.focus === "function") el.focus()
        }, 0)
      })
    })
  }

  disconnect() {
    if (this.focusTimer) {
      clearTimeout(this.focusTimer)
      this.focusTimer = null
    }
  }

  modifiedClick(event) {
    return event.defaultPrevented ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      event.button !== 0
  }
}
