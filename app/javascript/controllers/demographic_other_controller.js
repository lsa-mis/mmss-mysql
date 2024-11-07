import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["otherField"]

  connect() {
    console.log("Demographic controller connected")
    if (this.hasOtherFieldTarget) {
      this.otherFieldTarget.classList.add('hidden')
      this.initializeFieldState()
    }
  }

  initializeFieldState() {
    console.log("Initializing field state")
    const selectElement = this.element.querySelector('select')
    if (selectElement) {
      const selectedOption = selectElement.options[selectElement.selectedIndex]
      this.toggleVisibility(selectedOption)
    }
  }

  toggleOtherField(event) {
    console.log("Toggle field triggered", event.target.value)
    const selectedOption = event.target.options[event.target.selectedIndex]
    this.toggleVisibility(selectedOption)
  }

  toggleVisibility(selectedOption) {
    console.log("Toggling visibility for:", selectedOption?.text)
    if (!this.hasOtherFieldTarget) return

    const isOther = selectedOption && selectedOption.text.trim().toLowerCase() === 'other'
    const input = this.otherFieldTarget.querySelector('input')
    
    if (isOther) {
      this.otherFieldTarget.classList.remove('hidden')
      input.required = true
      input.setAttribute('aria-required', 'true')
    } else {
      this.otherFieldTarget.classList.add('hidden')
      input.required = false
      input.removeAttribute('aria-required')
      input.value = ''
    }
  }
}