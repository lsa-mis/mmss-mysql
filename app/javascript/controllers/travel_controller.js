import { Controller } from 'stimulus';
export default class extends Controller {
  static targets = ["depart", "arrival", "message", "arrival_transport", "arrrival_details", "depart_transport", "depart_details"]

  checkDates(event) {
    console.log("nothing)")

    let arrival = this.arrivalTarget.value;
    let depart = this.departTarget.value;

    if (typeof arrival !== 'undefined' && typeof depart !== 'undefined') {
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

  checkArrivalTransport(event) {
    let transport = event.target.value
    if (transport.includes("Automobile") || transport.includes("commuter")) {
      this.arrrival_detailsTarget.classList.remove("travel-details--show")
      this.arrrival_detailsTarget.classList.add("travel-details--hide")

    }
    else {
      this.arrrival_detailsTarget.classList.add("travel-details--show")
      this.arrrival_detailsTarget.classList.remove("travel-details--hide")
    }
  }

  checkDepartTransport(event) {
    let transport = event.target.value
    if (transport.includes("Automobile") || transport.includes("commuter")) {
      this.depart_detailsTarget.classList.remove("travel-details--show")
      this.depart_detailsTarget.classList.add("travel-details--hide")
    }
    else {
      this.depart_detailsTarget.classList.add("travel-details--show")
      this.depart_detailsTarget.classList.remove("travel-details--hide")
    }
  }
}

