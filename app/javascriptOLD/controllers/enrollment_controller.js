import { Controller } from 'stimulus';
export default class extends Controller {
  static targets = ["session", "checkbox", "courses"]

  connect() {
    var checked = this.checkboxTargets.filter(checkbox => checkbox.checked)
    checked.forEach((el) => {
      if (el.dataset.index == 0) {
        this.appendMessage()
      }
      if (el.dataset.index > 0) {
        this.showSession(el.dataset.index)
        this.showCourses(el.dataset.index)
      }
    })
  }

  display_toggle_session() {
    var item_index = event.currentTarget.dataset.index
    // alert("current_target: " + item_index);

    if (item_index > 0) {
      this.uncheckAll(item_index)
      this.showSession(item_index)
      this.showCourses(item_index)
    }
    if (item_index == 0) {
      this.appendMessage()
    }
  }

  showSession(index) {
    this.index = index
    this.sessionTargets[index - 1].classList.toggle("session--hide")
  }

  showCourses(index) {
    this.index = index
    this.coursesTargets[index - 1].classList.toggle("session--hide")
  }

  appendMessage() {
    if ($('#any_message').length > 0) {
      $('#any_message').remove();
    } else {
      $('.form-checkbox[data-index="0"]').parent().after("<span id='any_message'><br>Also check all the boxes corresponding to each of the sessions you are able to attend.</span>");
    }
  }

  uncheckAll(divid) {
    $('#sessionActivity' + divid + ' :checkbox:enabled').prop('checked', false);
    $('#sessionCourses' + divid + ' :checkbox:enabled').prop('checked', false);
  }
}