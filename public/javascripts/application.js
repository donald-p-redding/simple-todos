$(function() {

  //Handles deletions via XML. No page referesh when deleting todo items.
  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure. This cannot be undone.");

    if (ok) {
      var form = $(this);

      var response = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      response.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status === 204) {
          form.parent('li').remove();
        } else if (jqXHR.status === 200) {
          document.location = data
        }
      });
    }

  });

});
