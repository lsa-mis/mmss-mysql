import { Controller } from 'stimulus';
export default class extends Controller {
  static targets = ["depart", "arrival", "message"]

  checkDates(event) {
    let arrival = this.arrivalTarget.value;
    let depart = this.departTarget.value;

    if (typeof arrival !== 'undefined' && typeof arrival !== 'undefined') {
      var d_arrival = Date.parse(arrival)
      var d_depart = Date.parse(depart)
      if (d_depart < d_arrival) {
        this.messageTarget.classList.add("date-error--display")
        this.messageTarget.classList.remove("date-error--hide")
        this.messageTarget.innerText = "Departure date should occur after Arrival date";
        event.preventDefault()
      }
      else {
        this.messageTarget.classList.add("date-error--hide")
        this.messageTarget.classList.remove("date-error--display")
        this.messageTarget.innerText = " "
      }
    }
  }
}

