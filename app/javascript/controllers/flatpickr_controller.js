import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
// flatpickr's stylesheet is bundled via app/assets/tailwind/application.css.

export default class extends Controller {
  static values = {
    minDate: String,
    maxDate: String,
  }

  connect() {
    flatpickr(this.element, {
      altInput: true,
      altFormat: "F j, Y",
      dateFormat: "Y-m-d",
      minDate: this.minDateValue,
      maxDate: this.maxDateValue,
    })
  }
}
