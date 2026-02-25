// app/javascript/controllers/character_counter_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="character-counter"
// Updates a counter element to show "X / max" or "X characters, Y remaining"
export default class extends Controller {
  static values = {
    max: { type: Number, default: 255 }
  }

  static targets = ["input", "counter"]

  connect() {
    this.updateCounter()
    this.inputTarget.addEventListener("input", this.boundUpdate = this.updateCounter.bind(this))
  }

  disconnect() {
    if (this.boundUpdate && this.hasInputTarget) {
      this.inputTarget.removeEventListener("input", this.boundUpdate)
    }
  }

  updateCounter() {
    if (!this.hasInputTarget || !this.hasCounterTarget) return

    const length = (this.inputTarget.value || "").length
    const max = this.maxValue
    const remaining = Math.max(0, max - length)

    this.counterTarget.textContent = `${length} / ${max} characters`
    this.counterTarget.setAttribute("aria-live", "polite")

    // Optional: add a class when near or over limit for styling
    this.counterTarget.classList.remove("text-muted", "text-warning", "text-danger")
    if (length > max) {
      this.counterTarget.classList.add("text-danger")
    } else if (remaining <= 20) {
      this.counterTarget.classList.add("text-warning")
    } else {
      this.counterTarget.classList.add("text-muted")
    }
  }
}
