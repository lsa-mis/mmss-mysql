
function hidesubmit() {
  if ($("#recupload_recletter").val() == "" && $("#recupload_letter").val() == "") {
    // alert("hide");
    // console.log($("#recupload_letter").val())
    $(':submit').hide();
  } else {
    // console.log($("#recupload_letter").val())
    // alert("show");
    $(':submit').show();
  }
}

$(function () {
  hidesubmit();
  // Hide submit button if either field is empty
  $('#recupload_letter').on("change input paste keyup textarea", function () {
    hidesubmit();
  });

  $('input[type="file"]').change(function () {
    hidesubmit();
  });
});