// Restores keyboard focus after Turbo Drive replaces the page from a filter or
// sort navigation (LRA-1522). Capture a stable id before navigation; on connect
// (new page), focus the matching control.
import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "mmss-admin-focus-preserve"

export default class extends Controller {
  connect() {
    this.restore()
  }

  // Sort header links and Clear filters.
  capture(event) {
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
}
