import { Controller } from "@hotwired/stimulus"

// Add/remove rows for `accepts_nested_attributes_for` associations.
//
// <div data-controller="nested-form">
//   <template data-nested-form-target="template"> ...fields with NEW_RECORD as the index... </template>
//   <div data-nested-form-target="container"> ...existing rows (data-nested-form-target="row")... </div>
//   <button type="button" data-action="nested-form#add">Add</button>
// </div>
//
// Each row contains a hidden `_destroy` input (data-nested-form-target="destroy") and a remove
// button with data-action="nested-form#remove".
export default class extends Controller {
  static targets = ["template", "container", "row"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime().toString())
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-target~='row']")
    if (!row) return

    const destroyInput = row.querySelector("input[name*='_destroy']")
    if (destroyInput && row.dataset.persisted === "true") {
      destroyInput.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
