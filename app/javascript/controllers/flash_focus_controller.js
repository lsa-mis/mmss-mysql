// Moves keyboard focus to a flash alert after a failed form submit / reload
// so screen-reader and keyboard users hear the status message (LRA-1511, LRA-1513).
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.focus()
  }
}
