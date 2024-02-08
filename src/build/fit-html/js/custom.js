// Popovers and hints

// Fix popovers in math equations
function addHints() {
  // console.log('Called...')

  $('.mathpopup').each(function (index) {
    var anchor = $(this).parent();
    var href = anchor.attr('href') // this contains the hint!

    if (href) {
      // dump when debugging...
      // console.log('Found one!')
      // console.log(href);

      anchor.removeAttr('href')
      anchor.addClass('fix-popover')
      anchor.attr('tabindex', '0')
      anchor.attr('role', 'button')
      anchor.attr('data-bs-trigger', 'focus')
      anchor.attr('data-bs-container', 'body')
      anchor.attr('data-bs-toggle', 'popover')
      anchor.attr('data-bs-html', 'true')
      anchor.attr('data-bs-placement', 'top')
      anchor.attr('data-bs-content', href)
    }
  });

  $('.fix-popover').each(function () {
    new bootstrap.Popover($(this));
    $(this).on('shown.bs.popover', function () {
      MathJax.typeset();
    });
  });

  $('.fix-popover').removeClass('fix-popover');
  $('.mathpopup').removeClass('mathpopup');  
}


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
  MathJax.typeset();
});

// Theme switching 
pygments_themes = {
  "light": "css/highlight.css",
  "dark": "css/highlight-dark.css"
}

pygments_theme_link = $('#pygments-theme-link')
current_theme = localStorage.getItem('current-woowoo-theme') || 'light'

document.documentElement.setAttribute('data-bs-theme', current_theme)
pygments_theme_link.attr('href', pygments_themes[current_theme])
if (current_theme == 'dark') {
  $('img.woowoo-image, img.woowoo-tikz, span.mjx-mstyle').addClass('fix-dark')
  $('#theme-switch-icon').removeClass('fa-moon')
  $('#theme-switch-icon').addClass('fa-sun')
}

$('#theme-switch-link').click(function() {
  pygments_theme_link = $('#pygments-theme-link')
  current_theme = localStorage.getItem('current-woowoo-theme') || 'light'

  if (current_theme == 'dark') {
    $("html").fadeOut(1000, function () {
      // console.log('Going light...')
      document.documentElement.setAttribute('data-bs-theme', 'light')
      pygments_theme_link.attr('href', pygments_themes['light'])
      $('img.woowoo-image, img.woowoo-tikz, mjx-mstyle').removeClass('fix-dark')
      localStorage.setItem('current-woowoo-theme', 'light')
      $('#theme-switch-icon').removeClass('fa-sun')
      $('#theme-switch-icon').addClass('fa-moon')
      $("html").fadeIn(1000)
    });
  } else {
    $("html").fadeOut(1000, function () {
      // console.log('Going dark...')
      document.documentElement.setAttribute('data-bs-theme', 'dark')
      pygments_theme_link.attr('href', pygments_themes['dark'])
      $('img.woowoo-image, img.woowoo-tikz, mjx-mstyle').addClass('fix-dark')
      localStorage.setItem('current-woowoo-theme', 'dark')
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

