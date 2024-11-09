// app/javascript/controllers/required_stars_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.addRequiredAsterisks()
  }

  addRequiredAsterisks() {
    // Select all required input fields within the controller's scope
    const requiredFields = this.element.querySelectorAll("input[required], select[required], textarea[required]")

    requiredFields.forEach((field) => {
      const label = this.element.querySelector(`label[for='${field.id}']`)
      if (label && !label.querySelector(".required-star")) {
        const span = document.createElement("span")
        span.textContent = " *"
        span.classList.add("required-star", "text-red-500")
        label.appendChild(span)
      }
    })
  }
}