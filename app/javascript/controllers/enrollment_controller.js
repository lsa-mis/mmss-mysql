import { Controller } from "@hotwired/stimulus"

// Shows/hides the per-session activity and course blocks on the application
// form as session checkboxes are toggled. Index 0 is the "Any Session" box.
export default class extends Controller {
  static targets = ["session", "checkbox", "courses"]

  connect() {
    this.checkboxTargets
      .filter((checkbox) => checkbox.checked)
      .forEach((checkbox) => {
        const index = Number(checkbox.dataset.index)
        if (index === 0) this.toggleMessage()
        if (index > 0) {
          this.showSession(index)
          this.showCourses(index)
        }
      })
  }

  display_toggle_session(event) {
    const index = Number(event.currentTarget.dataset.index)

    if (index > 0) {
      this.uncheckAll(index)
      this.showSession(index)
      this.showCourses(index)
    }
    if (index === 0) {
      this.toggleMessage()
    }
  }

  showSession(index) {
    this.sessionTargets[index - 1]?.classList.toggle("session--hide")
  }

  showCourses(index) {
    this.coursesTargets[index - 1]?.classList.toggle("session--hide")
  }

  toggleMessage() {
    const existing = document.getElementById("any_message")
    if (existing) {
      existing.remove()
      return
    }

    const anyBox = this.checkboxTargets.find((checkbox) => checkbox.dataset.index === "0")
    if (!anyBox || !anyBox.parentElement) return

    const message = document.createElement("span")
    message.id = "any_message"
    message.appendChild(document.createElement("br"))
    message.appendChild(
      document.createTextNode(
        "Also check all the boxes corresponding to each of the sessions you are able to attend."
      )
    )
    anyBox.parentElement.after(message)
  }

  uncheckAll(index) {
    ;[`#sessionActivity${index}`, `#sessionCourses${index}`].forEach((selector) => {
      document
        .querySelectorAll(`${selector} input[type="checkbox"]:enabled`)
        .forEach((checkbox) => (checkbox.checked = false))
    })
  }
}
