// Moves keyboard focus to a flash alert after a failed form submit / reload
// so screen-reader and keyboard users hear the status message (LRA-1511, LRA-1513).
//
// Turbo Drive may autofocus another field after Stimulus connects; defer until after
// paint + a macrotask so we win that race, then bail if this element was replaced.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scheduleFocus()
  }

  disconnect() {
    if (this.focusTimer) {
      clearTimeout(this.focusTimer)
      this.focusTimer = null
    }
  }

  scheduleFocus() {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.focusTimer = setTimeout(() => {
          this.focusTimer = null
          if (!this.element.isConnected) return
          this.element.focus()
        }, 0)
      })
    })
  }
}
