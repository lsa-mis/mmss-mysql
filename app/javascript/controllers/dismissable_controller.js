import { Controller } from "@hotwired/stimulus"

// Removes the element (e.g. a flash message) when its dismiss button is clicked.
export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
}
