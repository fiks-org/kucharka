// Popovers

MathJax.Hub.Queue(function () {
  // Fix popovers in math equations
  $('span.mathpopup').each(function (index) {
    var anchor = $(this).parent();
    var href = anchor.attr('href') // this contains the hint!

    // dump when debugging...
    // console.log(href)

    anchor.removeAttr('href')
    anchor.attr('tabindex', '0')
    anchor.attr('role', 'button')
    anchor.attr('data-bs-trigger', 'focus')
    anchor.attr('data-bs-container', 'body')
    anchor.attr('data-bs-toggle', 'popover')
    anchor.attr('data-bs-html', 'true')
    anchor.attr('data-bs-placement', 'top')
    anchor.attr('data-bs-content', href)
    anchor.addClass('bg-light')
    anchor.addClass('text-success')
  });

  var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
  });

  $('[data-bs-toggle="popover"]').on('shown.bs.popover', function () {
    MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
  });
});


// Bootstrap tooltips
//
// see https://getbootstrap.com/docs/5.1/components/tooltips/#example-enable-tooltips-everywhere

var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
  return new bootstrap.Tooltip(tooltipTriggerEl)
})

// AnchorJS

anchors.options.placement = 'right';
anchors.add('.anchored');

// Popovers
//
// see https://getbootstrap.com/docs/5.1/components/popovers/#example-enable-popovers-everywhere

var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
  return new bootstrap.Popover(popoverTriggerEl)
})

// Typeset possible math content in popovers

$('[data-bs-toggle="popover"]').on('shown.bs.popover', function () {
  MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
});

// Hackish theme switching 
bs_themes = {
  "default": "css/bootstrap.min.css",
  "darkly": "css/bootstrap-darkly.min.css"
}
pygments_themes = {
  "default": "css/highlight.css",
  "darkly": "css/highlight-dark.css"
}

bs_theme_link = $('#bs-theme-link')
pygments_theme_link = $('#pygments-theme-link')
current_theme = localStorage.getItem('current-woowoo-theme') || 'default'

bs_theme_link.attr('href', bs_themes[current_theme])
pygments_theme_link.attr('href', pygments_themes[current_theme])
if (current_theme == 'darkly') {
  $('img.woowoo-image, img.woowoo-tikz').addClass('fix-dark')
  $('#theme-switch-icon').removeClass('fa-moon')
  $('#theme-switch-icon').addClass('fa-sun')
}

$('#theme-switch-link').click(function() {
  bs_theme_link = $('#bs-theme-link')
  pygments_theme_link = $('#pygments-theme-link')
  current_theme = localStorage.getItem('current-woowoo-theme') || 'default'

  if (current_theme == 'darkly') {
    $("html").fadeOut(1000, function () {
      bs_theme_link.attr('href', bs_themes['default'])
      pygments_theme_link.attr('href', pygments_themes['default'])
      $('img.woowoo-image, img.woowoo-tikz').removeClass('fix-dark')
      localStorage.setItem('current-woowoo-theme', 'default')
      $('#theme-switch-icon').removeClass('fa-sun')
      $('#theme-switch-icon').addClass('fa-moon')
      $("html").fadeIn(1000)
    });
  } else {
    $("html").fadeOut(1000, function () {
      bs_theme_link.attr('href', bs_themes['darkly'])
      pygments_theme_link.attr('href', pygments_themes['darkly'])
      $('img.woowoo-image, img.woowoo-tikz').addClass('fix-dark')
      localStorage.setItem('current-woowoo-theme', 'darkly')
      $('#theme-switch-icon').removeClass('fa-moon')
      $('#theme-switch-icon').addClass('fa-sun')
      $("html").fadeIn(1000)
    });
  }
});

// render pseudocode
$('pre.pseudocode').each( function (index) {
  pseudocode.renderElement($(this)[0], { lineNumber: true });  
});

