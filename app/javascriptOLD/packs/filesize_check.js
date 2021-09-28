var MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
$(document).ready(function () {
    $('input:file').change(function () {
        fileSize = this.files[0].size;
        if (fileSize > MAX_FILE_SIZE) {
            this.setCustomValidity("File must not exceed 5 MB!");
            this.reportValidity();
        } else {
            this.setCustomValidity("");
        }
    });
});