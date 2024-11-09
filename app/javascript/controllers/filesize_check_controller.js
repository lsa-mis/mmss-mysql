// app/javascript/controllers/filesize_check_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    maxFileSize: Number
  }

  connect() {
    this.maxFileSize = this.maxFileSizeValue || 20 * 1024 * 1024 // Default to 20MB
  }

  validateFileSize(event) {
    const input = event.target
    const file = input.files[0]

    if (file && file.size > this.maxFileSize) {
      input.setCustomValidity("File must not exceed 20 MB!")
      input.reportValidity()
    } else {
      input.setCustomValidity("")
    }
  }
}