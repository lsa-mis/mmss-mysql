import { Controller } from "@hotwired/stimulus"

// Row checkboxes + "select all" for admin index tables with batch actions.
// Enables the Apply button only when at least one row is selected.
export default class extends Controller {
  static targets = ["all", "row", "submit", "count"]

  connect() {
    this.update()
  }

  toggleAll(event) {
    this.rowTargets.forEach((checkbox) => { checkbox.checked = event.target.checked })
    this.update()
  }

  toggle() {
    this.update()
  }

  update() {
    const selected = this.rowTargets.filter((checkbox) => checkbox.checked).length
    const total = this.rowTargets.length

    if (this.hasAllTarget) {
      this.allTarget.checked = total > 0 && selected === total
      this.allTarget.indeterminate = selected > 0 && selected < total
    }
    if (this.hasSubmitTarget) this.submitTarget.disabled = selected === 0
    if (this.hasCountTarget) this.countTarget.textContent = selected > 0 ? `${selected} selected` : ""
  }
}
