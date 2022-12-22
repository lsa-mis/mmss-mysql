import { Controller } from 'stimulus';
export default class extends Controller {
  static targets = ["form", "depart", "arrival", "message", "arrival_transport", "arrival_details", "depart_transport", "depart_details",
    "arrival_date_time", "depart_date_time", "arrival_message",
    "arrival_carrier", "arrival_route_num", "arrival_time", "arrival_message",
    "depart_carrier", "depart_route_num", "depart_time", "depart_message",
  ]

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

  checkArrivalTransport() {
    let transport = this.arrival_transportTarget.value;
    console.log(transport)
    if (transport.includes("Automobile")) {
      this.arrival_detailsTarget.classList.remove("travel-details--show")
      this.arrival_detailsTarget.classList.add("travel-details--hide")
      this.arrival_date_timeTarget.classList.remove("travel-details--hide")
      this.arrival_date_timeTarget.classList.add("travel-details--show")
    }
    else if (transport.includes("commuter")) {
      this.arrival_detailsTarget.classList.remove("travel-details--show")
      this.arrival_detailsTarget.classList.add("travel-details--hide")
      this.arrival_date_timeTarget.classList.remove("travel-details--show")
      this.arrival_date_timeTarget.classList.add("travel-details--hide")
    }
    else {
      this.arrival_detailsTarget.classList.add("travel-details--show")
      this.arrival_detailsTarget.classList.remove("travel-details--hide")
      this.arrival_date_timeTarget.classList.add("travel-details--show")
      this.arrival_date_timeTarget.classList.remove("travel-details--hide")
    }
  }

  checkDepartTransport() {
    console.log("hell");

    let transport = this.depart_transportTarget.value;
    if (transport.includes("Automobile")) {
      this.depart_detailsTarget.classList.remove("travel-details--show")
      this.depart_detailsTarget.classList.add("travel-details--hide")
      this.depart_date_timeTarget.classList.remove("travel-details--hide")
      this.depart_date_timeTarget.classList.add("travel-details--show")
    }
    else if (transport.includes("commuter")) {
      this.depart_detailsTarget.classList.remove("travel-details--show")
      this.depart_detailsTarget.classList.add("travel-details--hide")
      this.depart_date_timeTarget.classList.remove("travel-details--show")
      this.depart_date_timeTarget.classList.add("travel-details--hide")
    }
    else {
      this.depart_detailsTarget.classList.add("travel-details--show")
      this.depart_detailsTarget.classList.remove("travel-details--hide")
      this.depart_date_timeTarget.classList.add("travel-details--show")
      this.depart_date_timeTarget.classList.remove("travel-details--hide")
    }
  }

  submitForm(event) {
    let no_submit = "false";
    console.log("submit");
    let arrival_transport = this.arrival_transportTarget.value;
    let depart_transport = this.depart_transportTarget.value;

    console.log(arrival_transport)
    console.log(depart_transport)

    if (arrival_transport.includes("commuter")) {
      this.arrival_carrierTarget.value = "";
      this.arrival_route_numTarget.value = "";
      this.arrivalTarget.value = "";
      this.arrival_timeTarget.value = "";
    }

    if (arrival_transport.includes("Airplane") || arrival_transport.includes("Train") || arrival_transport.includes("Bus")) {
      console.log("works");
      var arrival_carrier = this.arrival_carrierTarget.value;
      console.log(this.arrival_carrierTarget);
      console.log(arrival_carrier);
      var arrival_route_num = this.arrival_route_numTarget.value;
      let arrival = this.arrivalTarget.value;
      var arrival_time = this.arrival_timeTarget.value;
      console.log(arrival_route_num);
      console.log(arrival);
      console.log(arrival_time);
      if (arrival_carrier == "" || arrival_route_num == "" || arrival == "" || arrival_time == "") {
        console.log("empty");
        this.arrival_messageTarget.classList.add("date-error--display")
        this.arrival_messageTarget.classList.remove("date-error--hide")
        this.arrival_messageTarget.innerText = "Fill out all arrival information";
        event.preventDefault();
        event.stopImmediatePropagation()
      }
      else {
        this.arrival_messageTarget.innerText = "";
        this.arrival_messageTarget.classList.remove("date-error--display")
        this.arrival_messageTarget.classList.add("date-error--hide")
      }
    }
    if (arrival_transport.includes("Automobile")) {
      console.log("works");
      var arrival = this.arrivalTarget.value;
      var arrival_time = this.arrival_timeTarget.value;
      if (arrival == "" || arrival_time == "") {
        console.log("empty");
        this.arrival_messageTarget.classList.add("date-error--display")
        this.arrival_messageTarget.classList.remove("date-error--hide")
        this.arrival_messageTarget.innerText = "Fill out all arrival information";
        event.preventDefault();
        event.stopImmediatePropagation()
      }
      else {
        this.arrival_messageTarget.innerText = "";
        this.arrival_messageTarget.classList.remove("date-error--display")
        this.arrival_messageTarget.classList.add("date-error--hide")

      }
    }

    if (depart_transport.includes("commuter")) {
      this.depart_carrierTarget.value = "";
      this.depart_route_numTarget.value = "";
      this.departTarget.value = "";
      this.depart_timeTarget.value = "";
    }

    if (depart_transport.includes("Airplane") || depart_transport.includes("Train") || depart_transport.includes("Bus")) {
      console.log("depart works");
      var depart_carrier = this.depart_carrierTarget.value;
      console.log(depart_carrier);
      var depart_route_num = this.depart_route_numTarget.value;
      var depart = this.departTarget.value;
      var depart_time = this.depart_timeTarget.value;
      console.log(depart_route_num);
      console.log(depart);
      console.log(depart_time);
      if (depart_carrier == "" || depart_route_num == "" || depart == "" || depart_time == "") {
        console.log("depart empty");
        this.depart_messageTarget.classList.add("date-error--display")
        this.depart_messageTarget.classList.remove("date-error--hide")
        this.depart_messageTarget.innerText = "Fill out all depart information";
        event.preventDefault();
        event.stopImmediatePropagation()
      }
      else {
        console.log("depart remove");
        this.depart_messageTarget.innerText = "";
        this.depart_messageTarget.classList.remove("date-error--display")
        this.depart_messageTarget.classList.add("date-error--hide")

      }
    }
    if (depart_transport.includes("Automobile")) {
      console.log("works");
      var depart = this.departTarget.value;
      var depart_time = this.depart_timeTarget.value;
      this.depart_carrierTarget.value = "";
      this.depart_route_numTarget.value = "";
      if (depart == "" || depart_time == "") {
        console.log("empty");
        this.depart_messageTarget.classList.add("date-error--display")
        this.depart_messageTarget.classList.remove("date-error--hide")
        this.depart_messageTarget.innerText = "Fill out all depart information";
        event.preventDefault();
        event.stopImmediatePropagation()
      }
      else {
        this.depart_messageTarget.innerText = "";
        this.depart_messageTarget.classList.remove("date-error--display")
        this.depart_messageTarget.classList.add("date-error--hide")

      }
    }
    // if (no_submit) {
    //   console.log("no submit");
    //   event.preventDefault();
    //   event.stopImmediatePropagation()
    // }
    // else {
    console.log("all is ok");
    // }
  }
}
