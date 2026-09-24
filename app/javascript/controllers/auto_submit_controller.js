import { Controller } from "@hotwired/stimulus"

// Submits the surrounding form when a control changes (e.g. the per-page selector).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
