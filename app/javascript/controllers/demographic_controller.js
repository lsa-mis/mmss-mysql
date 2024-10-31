import { Controller } from 'stimulus'; 
export default class extends Controller {
  static targets = ["list", "other_demographic_div", "other_demographic"]

  connect() {
    console.log("connect demographic")
  }

  getDemographic() {
    var demographic_id = this.listTarget.value
    console.log(demographic_id)
    if (demographic_id) {
      fetch(`/demographics/get_demographic_value/${demographic_id}`)
        .then((response) => response.json())
        .then((data) => this.otherDemographic(data)
        );
    } 
  }

  otherDemographic(data){
    console.log(data)
    var demographic = data["name"].toLowerCase()    
    var other_demographic = document.getElementById("applicant_detail_other_demographic");

    if (demographic == 'other') {
      other_demographic.required = true;
      this.other_demographicTarget.value = ""
      this.other_demographic_divTarget.classList.remove("fields--hide")
      this.other_demographic_divTarget.classList.add("fields--display")
    }
    else {
      console.log("hell")
      other_demographic.required = false;
      this.other_demographicTarget.value = ""
      this.other_demographic_divTarget.classList.add("fields--hide")
      this.other_demographic_divTarget.classList.remove("fields--display")
    }
  }

}
