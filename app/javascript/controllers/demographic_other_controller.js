import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["otherfield"]

  connect() {
    if (this.hasOtherfieldTarget) {
      this.otherfieldTarget.classList.add('hidden')
      this.initializeFieldState()
    }
  }

  initializeFieldState() {
    const selectElement = this.element.querySelector('select')
    if (selectElement) {
      const selectedOption = selectElement.options[selectElement.selectedIndex]
      this.toggleVisibility(selectedOption)
    }
  }

  toggleOtherField(event) {
    const selectedOption = event.target.options[event.target.selectedIndex]
    this.toggleVisibility(selectedOption)
  }

  toggleVisibility(selectedOption) {
    if (!this.hasOtherfieldTarget) return

    const isOther = selectedOption && selectedOption.text.trim().toLowerCase() === 'other'
    const input = this.otherfieldTarget.querySelector('input')

    if (isOther) {
      this.otherfieldTarget.classList.remove('hidden')
      input.required = true
      input.setAttribute('aria-required', 'true')
    } else {
      this.otherfieldTarget.classList.add('hidden')
      input.required = false
      input.removeAttribute('aria-required')
      input.value = ''
    }
  }
}
