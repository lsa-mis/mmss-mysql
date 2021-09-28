
function hidesubmit(){
  if ($("#enrollment_student_packet").val() == "" ) {
    $('#student_packet_submit').hide();
  } else {
    $('#student_packet_submit').show();
  }
}

  $(function(){
    hidesubmit();

    $('#enrollment_student_packet').change(function() {
      hidesubmit();
    });
  });