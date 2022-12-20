var MAX_FILE_SIZE = 20 * 1024 * 1024; // 20MB
$(document).ready(function () {
    $('input:file').change(function () {
        fileSize = this.files[0].size;
        if (fileSize > MAX_FILE_SIZE) {
            this.setCustomValidity("File must not exceed 20 MB!");
            this.reportValidity();
        } else {
            this.setCustomValidity("");
        }
    });
});