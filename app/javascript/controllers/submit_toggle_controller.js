import { Controller } from "@hotwired/stimulus"

// Hides the form's submit button until at least one of the watched fields has
// a value (e.g. a typed recommendation letter or an uploaded file).
// Connects to data-controller="submit-toggle"; watched inputs use
// data-submit-toggle-target="field" and fire submit-toggle#update on change.
export default class extends Controller {
  static targets = ["field", "submit"]

  connect() {
    this.update()
  }

  update() {
    const filled = this.fieldTargets.some((field) => field.value !== "")
    this.submitTargets.forEach((button) => (button.hidden = !filled))
  }
}
