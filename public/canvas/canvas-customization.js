// jscs:disable maximumNumberOfLines
/* jshint camelcase: false */

(function(window, document, $) {
  'use strict';

  /* UTIL */

  /**
   * Perform a CalCentral API Get request
   *
   * @param  {String}     url                 The relative URL of the API request that should be made
   * @param  {Function}   callback            Standard callback function
   * @param  {Object}     callback.response   The API request response
   */
  var apiRequest = function(url, callback) {
    $.ajax({
      'dataType': 'json',
      'url': window.CALCENTRAL + url,
      'success': callback
    });
  };

  /**
   * Get the id for a custom LTI tool that user has access to
   *
   * @param  {String}     toolType            The classification of the LTI tool. This will be the top level property in the external tools hash
   * @param  {String}     toolName            The name of the LTI tool for which the id should be retrieved
   * @param  {Function}   callback            Standard callback function
   * @param  {String}     callback.id         The id of the requested custom LTI tool
   */
  var getExternalToolId = function(toolType, toolName, callback) {
    apiRequest('/api/academics/canvas/external_tools.json', function(externalToolsHash) {
      if (externalToolsHash && externalToolsHash[toolType]) {
        return callback(externalToolsHash[toolType][toolName]);
      } else {
        return callback(null);
      }
    });
  };

  // Keeps track of the elements to become available on the page
  var elementWaitList = [];

  /**
   * Wait until an element is available on the page
   *
   * @param  {String}     selector            The jQuery selector of the element for which presence is checked
   * @param  {Boolean}    repeat              Whether to continue checking for the existence of the element after it has been found for the first time. If `true`, the callback function will be executed every time the element is present
   * @param  {Function}   callback            Standard callback function
   * @param  {Element}    callback.element    The jQuery element that represent the element for which presence was found
   */
  var waitUntilAvailable = function(selector, repeat, callback) {
    // Add the element to the list of elements to check for existence on the page
    elementWaitList.push({
      'selector': selector,
      'repeat': repeat,
      'callback': callback
    });
  };

  /**
   * Check for the presence of elements in the waiting list on the page
   */
  var checkElements = function() {
    elementWaitList = elementWaitList.filter(function(element) {
      var $element = $(element.selector);
      if ($element.length > 0) {
        element.callback($element);
        return element.repeat ? true : false;
      } else {
        return true;
      }
    });
  };

  setInterval(checkElements, 200);

  /* CREATE A SITE */

  /**
   * Check whether the current user is allowed to create a new site
   *
   * @param  {Function}   callback                  Standard callback function
   * @param  {Element}    callback.canCreateSite    Whether the current user is allowed to create a new site
   */
  var canUserCreateSite = function(callback) {
    apiRequest('/api/academics/canvas/user_can_create_site?canvas_user_id=' + window.ENV.current_user_id, function(authResult) {
      return callback(authResult.canCreateSite);
    });
  };

  /**
   * Add the 'Create a Site' button that will provide access to the custom LTI tool
   * that allows a user to create a course site and/or a project site
   */
  var addCreateSiteButton = function() {
    // Only add the 'Create a Site' button from the dashboard or courses page
    if (['/', '/courses'].indexOf(window.location.pathname) !== -1 && window.ENV.current_user_id) {
      // Check if the user is allowed to create a new site
      canUserCreateSite(function(canCreateSite) {
        if (canCreateSite) {
          // Get the id of the Create Site LTI tool
          getExternalToolId('globalTools', 'Create a Site', function(createSiteId) {
            if (createSiteId) {
              var linkUrl = '/users/' + window.ENV.current_user_id + '/external_tools/' + createSiteId;
              var $createSiteButton = $('<a/>', {
                'href': linkUrl,
                'text': 'Create a Site',
                'class': 'btn btn-primary button-sidebar-wide'
              });

              // Add the 'Create a Site' button to the Dashboard page
              waitUntilAvailable('#right-side > div:not([class])', false, function($container) {
                $('#start_new_course').remove();
                $container.prepend($createSiteButton);
              });

              // Add the 'Create a Site' button to the Courses page
              waitUntilAvailable('.ic-Action-header', false, function($actionHeader) {
                $actionHeader.remove();
                // Add the button to the header
                var $headerBar = $('.header-bar');
                $('h2', $headerBar).addClass('pull-left');
                var $createSiteContainer = $('<div/>', {
                  'id': 'my-courses-create-site',
                  'class': 'text-right'
                }).append($createSiteButton);
                $headerBar.append($createSiteContainer);
              });
            }
          });
        }
      });
    }
  };

  /**
   * Remove the 'Create a Site' menu item from the 'User Settings' page
   * if the current user is not allowed to create a new site
   */
  var removeCreateSiteUserNav = function() {
    // Only attempt to remove the 'Create a Site' item on the 'User Settings' page
    if (window.location.pathname === '/profile/settings' && window.ENV.current_user_id) {
      // Remove the 'Create a Site' item if the current user is not allowed
      // to create a new site
      canUserCreateSite(function(canCreateSite) {
        if (canCreateSite) {
          waitUntilAvailable('nav ul#section-tabs li.section a:contains("Create a Site")', false, function($createSiteLink) {
            $createSiteLink.parent().remove();
          });
        }
      });
    }
  };

  addCreateSiteButton();
  removeCreateSiteUserNav();

  /* ACADEMIC POLICIES LINK */

  /**
   * Add 'Academic Policies' above 'Help' in left-hand global navigation
   */

  var addAcademicPoliciesLink = function() {
    waitUntilAvailable(".ic-app-header__menu-list .ic-app-header__menu-list-item:contains('Help')", false, function($helpMenuItem) {
      var $policiesMenuItem = $helpMenuItem.clone();

      $policiesMenuItem.find('.menu-item__text')
        .text('Academic Policies');
      $policiesMenuItem.find('a')
        .attr('id', 'global_nav_academic_policies_link')
        .attr('href', 'https://evcp.berkeley.edu/programs-resources/academic-accommodations-hub')
        .attr('target', '_blank')
        .attr('role', null)
        .attr('data-track-category', null)
        .attr('data-track-label', null);

      // Add SVG source for https://fontawesome.com/icons/university
      $policiesMenuItem.find('path')
        .attr('transform', 'scale(0.39,0.39)')
        .attr('d', 'M496 128v16a8 8 0 0 1-8 8h-24v12c0 6.627-5.373 12-12 12H60c-6.627 0-12-5.373-12-12v-12H24a8 8 0 0 1-8-8v-16a8 8 0 0 1 4.941-7.392l232-88a7.996 7.996 0 0 1 6.118 0l232 88A8 8 0 0 1 496 128zm-24 304H40c-13.255 0-24 10.745-24 24v16a8 8 0 0 0 8 8h464a8 8 0 0 0 8-8v-16c0-13.255-10.745-24-24-24zM96 192v192H60c-6.627 0-12 5.373-12 12v20h416v-20c0-6.627-5.373-12-12-12h-36V192h-64v192h-64V192h-64v192h-64V192H96z');

      $helpMenuItem.before($policiesMenuItem);
    });
  };

  addAcademicPoliciesLink();

  /* E-GRADES EXPORT */

  /**
   * Add the 'E-Grades' export option to the Canvas Gradebook
   */
  var addEGrades = function() {
    // Verify that the current context is the Gradebook tool
    if (window.ENV && window.ENV.GRADEBOOK_OPTIONS && window.ENV.GRADEBOOK_OPTIONS.context_id) {
      // Verify that the current course contains official course sections
      var courseId = window.ENV.GRADEBOOK_OPTIONS.context_id;
      apiRequest('/api/academics/canvas/egrade_export/is_official_course.json?canvas_course_id=' + courseId, function(officialCourseResponse) {
        if (officialCourseResponse.isOfficialCourse) {
          // Get the id of the E-Grades LTI tool
          getExternalToolId('officialCourseTools', 'Download E-Grades', function(gradesExportLtiId) {
            if (gradesExportLtiId) {
              var linkUrl = '/courses/' + courseId + '/external_tools/' + gradesExportLtiId;

              // Add the 'E-Grades' export option
              waitUntilAvailable('#gradebook-toolbar .gradebook-menus', false, function($gradebookToolbarMenu) {
                var eGradesButton = [
                  '<a class="ui-button" href="' + linkUrl + '">',
                  '  E-Grades',
                  '</a>'
                ].join('');
                $gradebookToolbarMenu.append(eGradesButton);
              });
            }
          });
        }
      });
    }
  };

  addEGrades();

  /* ADD PEOPLE */

  var customizations = function() {
    return {
      'peoplesearch_radio_cc_path': {
        'text': 'Email Address',
        'example': 'student@berkeley.edu, guest@example.com, gsi@berkeley.edu',
        'help': 'Please enter the email addresses of users you would like to add, separated by commas'
      },
      'peoplesearch_radio_unique_id': {
        'text': 'Berkeley UID',
        'example': '1032343, 11203443',
        'help': 'Please enter the UC Berkeley UIDs of users you would like to add, separated by commas.'
      },
      'peoplesearch_radio_sis_user_id': {
        'text': 'Student ID',
        'example': '25738808, UID:11203443',
        'help': 'Please enter the Student IDs of users you would like to add, separated by commas.'
      }
    };
  };

  var constructFindPersonLink = function(toolId) {
    if (toolId) {
      var linkUrl = window.ENV.COURSE_ROOT_URL + '/external_tools/' + toolId;
      return [
        '<div class="pull-right" id="calnet-directory-link">',
        '  <a href="' + linkUrl + '">',
        '    <i class="icon-search-address-book" aria-hidden="true"></i>',
        '    Find a Person to Add',
        '  </a>',
        '</div>'
      ].join('');
    }
  };

  /**
   * Customize help text of Add People text-area
   */
  var customizeAddPeopleTextArea = function(customization) {
    if (customization) {
      var textArea = $('[for^=TextArea__]');
      if (textArea.length > 0) {
        $('span:first span:first span:first span:first span:first span:first', textArea).text(customization.help);
        $('div:first span:nth-child(3)', textArea[0].parentNode).text(customization.example);
      }
    }
  };

  var onPeopleSearchRadioClick = function(event) {
    if (event && event.target && event.target.id) {
      var c = customizations();
      var keys = Object.keys(c);
      if (keys.indexOf(event.target.id) !== -1) {
        customizeAddPeopleTextArea(c[event.target.id]);
      }
    }
  };

  /**
   * Customize People tool of React-based Canvas UI
   */
  var customizeAddPeople = function() {
    var defaultRadioButtonId = 'peoplesearch_radio_cc_path';
    var modifiedMarker = 'calcentral-modified';

    waitUntilAvailable('[for=' + defaultRadioButtonId + ']:visible:not(.' + modifiedMarker + ')', true, function() {
      var c = customizations();
      customizeAddPeopleTextArea(c[defaultRadioButtonId]);
      // Class names are dynamically generated in Canvas' React-based UI.
      var labelStyle = '';
      // Modify radio buttons
      for (var id in c) {
        // JSHint demands the following conditional
        if (c.hasOwnProperty(id)) {
          var e = $('#' + id);
          if (e.length > 0) {
            $('[for=' + id + ']').addClass(modifiedMarker);

            // For Production as of 2017-12-15
            var label = $('[for=' + id + '] span:first span:last');
            if (label.length < 1) {
              // For Beta as of 2017-12-15
              label = $('[for=' + id + '] span:last');
            }
            label.text(c[id].text);
            labelStyle = label[0].className;
          }
        }
      }

      // Canvas's rendering is triggered by a click event listener on the document root.
      // To override it across browsers, we must append a click event listener on the same element.
      document.addEventListener('click', onPeopleSearchRadioClick);

      // Instructional text in footer of dialog
      var informational = $('.peoplesearch__instructions span:first');
      if (informational.length > 0) {
        informational.text('Add user by Email Address, Berkeley UID or Student ID.');
      }
      getExternalToolId('globalTools', 'Find a Person to Add', function(toolId) {
        var firstDiv = $('div.addpeople__peoplesearch');
        if (!firstDiv.hasClass(modifiedMarker)) {
          if (labelStyle) {
            firstDiv.addClass(labelStyle);
          } else {
            firstDiv[0].setAttribute('style', 'font-family: \'Lato\', \'Helvetica Neue\'');
          }
          firstDiv.prepend(constructFindPersonLink(toolId));
          firstDiv.addClass(modifiedMarker);
        }
      });
    });
  };

  /**
   * The legacy 'Add People' UI is identified by id 'create-users-step-1'.
   * TODO: Remove this legacy support once Canvas' new React-based UI is in production and reliable.
   */
  var customizeAddPeopleLegacy = function() {
    var modifiedMarker = 'calcentral-modified';

    // Add additional support to the first step
    waitUntilAvailable('#create-users-step-1:visible:not(.' + modifiedMarker + ')', true, function($createUserStep1) {
      $createUserStep1.addClass(modifiedMarker);
      // Replace instruction text
      var instructionText = 'Type or paste a list of email addresses or CalNet UIDs below:';
      $('p:first', $createUserStep1).text(instructionText);
      // Replace placeholder text
      var placeholderText = 'student@berkeley.edu, 323494, 1032343, guest@example.com, 11203443, gsi@berkeley.edu';
      $('#user_list_textarea', $createUserStep1).attr('placeholder', placeholderText);

      // Get the id of the Find a Person to Add LTI tool
      getExternalToolId('globalTools', 'Find a Person to Add', function(toolId) {
        $createUserStep1.prepend(constructFindPersonLink(toolId));
      });
    });
  };

  var extractBadUserInput = function(nameList) {
    // Extract user input from table elements.
    var userInput = [];
    var rows = $(':button[data-address]', nameList);
    for (var row in rows) {
      if (rows.hasOwnProperty(row) && rows[row].getAttribute) {
        var ref = rows[row].getAttribute('data-address');
        if (ref) {
          userInput.push(ref);
        }
      }
    }
    return (userInput.length > 0) ? '<div>Unable to find matches for ' + userInput.join(', ') + '. Please ensure they are formatted correctly.</div>' : '';
  };

  var helpTextForAddPeopleError = function() {
    return [
      '<div id="add-people-error-guests">',
      '  <strong>NOTE</strong>: If you are attempting to add a guest to your site who does NOT have a CalNet ID, they must first be sponsored.',
      '  For more information, see <a target="_blank" href="http://ets.berkeley.edu/bcourses/faq-page/7">Adding People to bCourses</a>.',
      '</div>'
    ].join('');
  };

  var addPeopleNextClickable = function(clickable) {
    var nextButton = $('#addpeople_next');
    if (nextButton.length > 0) {
      var b = nextButton[0];
      if (clickable) {
        b.removeAttribute('disabled');
        b.removeAttribute('aria-disabled');
      } else {
        b.setAttribute('disabled', 'true');
        b.setAttribute('aria-disabled', 'true');
      }
    }
  };

  var enableNextButton = function() {
    addPeopleNextClickable(true);
  };

  var listenersForAddPeopleError = function(backButton) {
    addPeopleNextClickable(false);
    // The 'Next' button will be re-enabled when user clicks 'Back' or 'Cancel'.
    backButton[0].addEventListener('click', enableNextButton);
    var cancelButton = backButton.siblings(':button').first();
    if (cancelButton.length > 0) {
      cancelButton[0].addEventListener('click', enableNextButton);
    }
  };

  /**
   * Customize Canvas' error dialog of Add People tool
   */
  var customizeAddPeopleError = function() {
    var modifiedMarker = 'calcentral-modified';

    waitUntilAvailable('#addpeople_back:visible:not(.' + modifiedMarker + ')', true, function($backButton) {
      $backButton.addClass(modifiedMarker);
      var validationError = $('.peoplevalidationissues__missing');
      if (validationError.length > 0) {
        // Add listeners to button
        listenersForAddPeopleError($backButton);
        // The following names were not found.
        var nameList = $('.addpeople__missing.namelist');
        var alertBox = $('div div', validationError);
        if (alertBox.length > 1) {
          // UC Berkeley's custom messaging
          alertBox.last().html('<div>' + extractBadUserInput(nameList) + helpTextForAddPeopleError() + '</div>');
        }
        // We remove the Canvas feature in which you can create new users using unrecognized input.
        nameList.remove();
      }
    });
  };

  /**
   * The legacy 'Add People' error UI is identified by id 'user_email_errors'.
   * TODO: Remove this legacy support once Canvas' new React-based UI is in production and reliable.
   */
  var customizeAddPeopleErrorLegacy = function() {
    var modifiedMarker = 'calcentral-modified';

    waitUntilAvailable('#user_email_errors:visible:not(.' + modifiedMarker + ')', true, function($userEmailErrors) {
      $userEmailErrors.addClass(modifiedMarker);
      // Set a custom error message
      var customErrorMessage = [
        '<div>These users had errors and will not be added. Please ensure they are formatted correctly.</div>',
        '<div><small>Examples: student@berkeley.edu, 323494, 1032343, guest@example.com, 11203443, gsi@berkeley.edu</small></div>'
      ].join('');
      $userEmailErrors.find('p').first().html(customErrorMessage);

      // Append a note for guest user addition
      $userEmailErrors.find('ul.createUsersErroredUsers').after(helpTextForAddPeopleError());
    });
  };

  /**
   * Add additional information to the Add People error message
   */
  var customizePeopleTools = function() {
    // Verify 'add_users' context
    if (window.ENV && window.ENV.permissions && window.ENV.permissions.add_users) {

      // First, give active tab an icon linked to ETS help page
      var modifiedMarker = 'calcentral-modified';

      waitUntilAvailable('#group_categories_tabs ul li a:first:not(.' + modifiedMarker + ')', true, function($activeTab) {
        $activeTab.after([
          '<a href="http://ets.berkeley.edu/bcourses/faq/adding-people" id="add-people-help" target="_blank">',
          '  <i class="icon-question" aria-hidden="true"></i>',
          '  <span class="screenreader-only">Need help adding someone to your site?</span>',
          '</a>'
        ].join(''));
        $activeTab.addClass(modifiedMarker);
      });

      // Customizations for both Canvas React-based UI and the legacy Canvas UI.
      customizeAddPeople();
      customizeAddPeopleLegacy();
      // The error page requires customization, too.
      customizeAddPeopleError();
      customizeAddPeopleErrorLegacy();
    }
  };

  customizePeopleTools();

  /* ALTERNATIVE MEDIA PANEL */

  /**
   * Check whether the current user can manage the files tool in the current course
   *
   * @return {Boolean}                        Whether the current user can manage the files tool
   */
  var canManageFilesTool = function() {
    return window.ENV.FILES_CONTEXTS[0] && window.ENV.FILES_CONTEXTS[0].permissions && window.ENV.FILES_CONTEXTS[0].permissions.manage_files;
  };

  /**
   * Add an 'Alternative Media' information panel for instructors to the 'Files' tool
   */
  var addAltMediaPanel = function() {
    if (canManageFilesTool) {
      var altMediaPanel = [
        '<div id="alt-media-container" class="alert alert-info">',
        '  <button class="btn-link element_toggler" aria-controls="alt-media-content" aria-expanded="false" aria-label="Notice to Instructors for Making Course Materials Accessible">',
        '    <i class="icon-arrow-right"></i> <strong>Instructors: Making Course Materials Accessible</strong>',
        '  </button>',
        '  <div id="alt-media-content" class="hide" role="region" tabindex="-1">',
        '    <ul>',
        '      <li>Without course instructor assistance, the University cannot meet its mission and responsibility to <a href="http://www.ucop.edu/electronic-accessibility/index.html" target="_blank">make online content accessible to students with disabilities</a></li>',
        '      <li><a href="http://www.dsp.berkeley.edu/what-inaccessible-content" target="_blank">How to improve the accessibility of your online content</a></li>',
        '      <li><a href="https://ets.berkeley.edu/sensusaccess" target="_blank">SensusAccess</a> -- your online partner in making documents accessible</li>',
        '      <li>Need Help? <a href="mailto:Assistive-technology@berkeley.edu" target="_blank">Contact Us</a></li>',
        '    </ul>',
        '  </div>',
        '</div>'
      ].join('');

      waitUntilAvailable('header.ef-header', false, function($header) {
        $header.before(altMediaPanel);

        // Toggle icon
        $('#alt-media-container .element_toggler').on('click', function() {
          $(this).find('i[class*="icon-arrow"]').toggleClass('icon-arrow-down icon-arrow-right');
        });
      });
    }
  };

  addAltMediaPanel();

  /* 404 PAGE */

  /**
   * Customize the default Canvas 404 page with bCourses support information
   */
  var pageNotFound = function() {
    // Verify that the current context is the error page
    waitUntilAvailable('#submit_error_form', false, function() {
      // Remove the default content and replace it with bCourses specific
      // support information
      $('#content h2').nextAll('*').remove();
      var pageNotFoundHelp = [
        '<p>Oops, we couldn\'t find that page! Contact the instructor or project site owner and let them know that something is missing.</p>',
        '<p>If you\'re still having a problem, email <a href="mailto:bcourseshelp@berkeley.edu">bcourseshelp@berkeley.edu</a> for support.</p>'
      ].join('');
      $('#content h2').after(pageNotFoundHelp);
    });
  };

  pageNotFound();

  /* WEBCAST */

  /**
   * Allow full screen for WebCast videos
   */
  var enableFullScreen = function() {
    waitUntilAvailable('#tool_content', false, function($toolContent) {
      $toolContent.attr('allowfullscreen', '');
    });
  };

  enableFullScreen();

  /* ALLY */

  /**
   * Load custom Ally JavaScript
   */
  var loadAllyCustomizations = function() {
    window.ALLY_CFG = {
      'baseUrl': 'https://prod.ally.ac',
      'clientId': 2
    };
    $.getScript(window.ALLY_CFG.baseUrl + '/integration/canvas/ally.js');
  };

  loadAllyCustomizations();

  /* FOOTER */

  /**
   * Customize the default footer with Berkeley information
   */
  var customizeFooter = function() {
    // Replace the Instructure logo with the Berkeley logo
    var $berkeleyLogo = $('<a>', {
      'class': 'footer-logo',
      'href': 'http://www.berkeley.edu',
      'title': 'University of California, Berkeley',
      'css': {
        'backgroundImage': 'url(' + window.CALCENTRAL + '/canvas/images/ucberkeley_footer.png)'
      }
    });
    $('#footer a.footer-logo').replaceWith($berkeleyLogo);

    // Replace the default footer links with the Berkeley footer links
    var footerLinks = [
      '<div class="footer-rows">',
      '  <div>',
      '    <a href="https://dls.berkeley.edu/services/bcourses-0" target="_blank">About</a>',
      '    <a href="http://www.canvaslms.com/policies/privacy" target="_blank">Privacy Policy</a>',
      '    <a href="http://www.canvaslms.com/policies/terms-of-use-internet2" target="_blank">Terms of Service</a>',
      '  </div>',
      '  <div>',
      '    <a href="https://dls.berkeley.edu/bcourses-data-use-and-analytics" target="_blank">Data Use &amp; Analytics</a>',
      '    <a href="http://teaching.berkeley.edu/berkeley-honor-code" target="_blank">UC Berkeley Honor Code</a>',
      '    <a href="https://asuc.org/resources/" target="_blank">Student Resources</a>',
      '  </div>',
      '</div>'
    ].join('');
    $('#footer-links').html(footerLinks);
  };

  customizeFooter();

  /* IFRAME COMMUNICATION */

  /**
   * We use window events to interact between the LTI iFrame and the parent container.
   * Resizing the iFrame based on its content is handled by Instructure's `public/javascripts/tool_inline.js`
   * file, and it determines the message format we use.
   *
   * The following custom events are provided for modifying the URL of the parent container:
   *
   *  - Change the location of the parent container:
   *    ```
   *     {
   *       subject: 'changeParent',
   *       parentLocation: <newLocation>
   *     }
   *    ```
   *
   *  - Change the hash of the parent container:
   *    ```
   *     {
   *       subject: 'setParentHash',
   *       'hash': <newHash>
   *     }
   *    ```
   *
   * The following custom event is provided to retrieve the URL of the parent container:
   *
   *  - Get the location of the parent container:
   *    ```
   *     {
   *       subject: 'getParent'
   *     }
   *    ```
   *
   * The following custom events are provided to support scrolling-related interaction between
   * the LTI iFrame and the parent container:
   *
   *  - Change the height of the LTI iFrame:
   *    ```
   *     {
   *       subject: 'changeParent',
   *       height: <height>
   *     }
   *    ```
   *
   *  - Scroll the parent container to a specified position:
   *    ```
   *     {
   *       subject: 'changeParent',
   *       scrollTo: <scrollPosition>
   *     }
   *    ```
   *
   *  - Scroll the parent container to the top of the screen:
   *    ```
   *     {
   *       subject: 'changeParent',
   *       scrollToTop: true
   *     }
   *    ```
   *
   *  - Get the scroll information of the parent container:
   *    ```
   *     {
   *       subject: 'getScrollInformation'
   *     }
   *    ```
   *
   *    Each of these events will respond with a window event back to the LTI iFrame containing the scroll information
   *    for the parent container:
   *    ```
   *     {
   *       iFrameHeight: <currentIframeHeight>,
   *       parentHeight: <currentParentHeight>,
   *       scrollPosition: <currentScrollPosition>,
   *       scrollToBottom: <currentHeightBelowFold>
   *     }
   *    ```
   *
   * @param  {Object}    ev         Event that is sent over from the iframe
   * @param  {String}    ev.data    The message sent with the event. Note that this is expected to be a stringified JSON object
   */
  window.onmessage = function(ev) {
    // Parse the provided event message
    if (ev && ev.data) {
      var message;
      try {
        message = JSON.parse(ev.data);
      } catch (err) {
        // The message is not for us; ignore it
        return;
      }

      var response = null;
      // Event that will modify the URL of the parent container
      if (message.subject === 'changeParent' && message.parentLocation) {
        window.location = message.parentLocation;

      // Event that retrieves the parent container's URL
      } else if (message.subject === 'getParent') {
        response = {
          'location': window.location.href
        };
        ev.source.postMessage(JSON.stringify(response), '*');

      // Event that will modify the hash of the parent container's URL
      } else if (message.subject === 'setParentHash') {
        history.replaceState(undefined, undefined, '#' + message.hash);

      // Events related to scrolling interaction between the LTI iFrame and the parent container
      } else if (message.subject === 'changeParent' || message.subject === 'getScrollInformation') {
        // Scroll to the specified position
        if (message.scrollTo !== undefined) {
          window.scrollTo(0, message.scrollTo);
        // Scroll to the top of the current window
        } else if (message.scrollToTop) {
          window.scrollTo(0, 0);
        } else if (message.height !== undefined) {
          if (!message.height || message.height < 450) {
            message.height = 450;
          }
          $('.tool_content_wrapper').height(message.height).data('height_overridden', true);
        }

        // Respond with a window event back to the LTI iFrame containing the scroll information for the parent container
        if (ev.source) {
          var iFrameHeight = $('.tool_content_wrapper').height();
          var parentHeight = $(document).height();
          var scrollPosition = $(document).scrollTop();
          var scrollToBottom = parentHeight - $(window).height() - scrollPosition;
          response = {
            'iFrameHeight': iFrameHeight,
            'parentHeight': parentHeight,
            'scrollPosition': scrollPosition,
            'scrollToBottom': scrollToBottom
          };
          ev.source.postMessage(JSON.stringify(response), '*');
        }
      }
    }
  };

})(window, window.document, window.$);

// jscs:enable maximumNumberOfLines
