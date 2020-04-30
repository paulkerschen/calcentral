'use strict';

/**
 * Canvas Add User to Course LTI app controller
 */
angular.module('calcentral.controllers').controller('CanvasCourseGradeExportController', function(apiService, canvasCourseGradeExportFactory, canvasSharedFactory, $http, $routeParams, $scope, $timeout, $window) {
  apiService.util.setTitle('E-Grade Export');
  $scope.accessibilityAnnounce = apiService.util.accessibilityAnnounce;

  $scope.appState = 'initializing';
  $scope.canvasCourseId = $routeParams.canvasCourseId || 'embedded';
  $scope.focusOnSelectionHeader = false;

  // Sends message to parent window to switch to gradebook
  $scope.goToGradebook = function() {
    var gradebookUrl = $scope.canvasRootUrl + '/courses/' + $scope.canvasCourseId + '/grades';
    if (apiService.util.isInIframe) {
      apiService.util.iframeParentLocation(gradebookUrl);
    } else {
      $window.location.href = gradebookUrl;
    }
  };

  // Sends message to parent window to go to Course Settings
  $scope.goToCourseSettings = function() {
    var courseDetailsUrl = $scope.canvasRootUrl + '/courses/' + $scope.canvasCourseId + '/settings#tab-details';
    if (apiService.util.isInIframe) {
      apiService.util.iframeParentLocation(courseDetailsUrl);
    } else {
      $window.location.href = courseDetailsUrl;
    }
  };

  // Updates status of background job in $scope. Halts jobStatusLoader loop if job no longer in progress.
  var statusProcessor = function(response) {
    angular.extend($scope, response.data);
    $scope.percentCompleteRounded = Math.round($scope.percentComplete * 100);
    if ($scope.jobStatus === 'Processing' || $scope.jobStatus === 'New') {
      jobStatusLoader();
    } else {
      delete $scope.percentCompleteRounded;
      $timeout.cancel(timeoutPromise);
      $scope.accessibilityAnnounce('Downloading export. Export form options presented for an additional download.');
      $scope.switchToSelection();
      downloadGrades();
    }
  };

  // Performs background job status request every 2000 miliseconds with result processed by statusProcessor.
  var timeoutPromise;
  var jobStatusLoader = function() {
    timeoutPromise = $timeout(function() {
      return canvasCourseGradeExportFactory.jobStatus($scope.canvasCourseId, $scope.backgroundJobId)
      .then(statusProcessor, function errorCallback() {
        $scope.errorStatus = 'error';
        $scope.contactSupport = true;
        $scope.displayError = 'Unable to obtain grade preloading status.';
      });
    }, 2000);
  };

  // Begins grade preparation and download process
  $scope.preloadGrades = function(type) {
    $scope.selectedType = type;
    $scope.appState = 'loading';
    $scope.appfocus = true;
    $scope.jobStatus = 'New';
    apiService.util.iframeScrollToTop();
    canvasCourseGradeExportFactory.prepareGradesCacheJob($scope.canvasCourseId).then(
      function successCallback(response) {
        if (response.data.jobRequestStatus === 'Success') {
          $scope.backgroundJobId = response.data.jobId;
          jobStatusLoader();
        } else {
          $scope.appState = 'error';
          $scope.contactSupport = true;
          $scope.errorStatus = 'Grade preloading request failed';
        }
      },
      function errorCallback() {
        $scope.appState = 'error';
        $scope.contactSupport = true;
        $scope.errorStatus = 'Grade preloading failed';
      }
    );
  };

  var initializePnpCutoffGrades = function() {
    $scope.letterGrades = ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F'];
    $scope.enablePnpConversion = 'true';
    $scope.selectedPnpCutoffGrade = null;
  };

  $scope.getExportOptions = function() {
    canvasCourseGradeExportFactory.exportOptions($scope.canvasCourseId).then(
      function successCallback(response) {
        if ($scope.appState !== 'error') {
          loadSectionTerms(response.data.sectionTerms);
        }
        if ($scope.appState !== 'error') {
          loadOfficialSections(response.data.officialSections);
        }
        if ($scope.appState !== 'error') {
          $scope.appState = 'preselection';
          if (!response.data.gradingStandardEnabled) {
            $scope.noGradingStandardEnabled = true;
          }
          initializePnpCutoffGrades();
        }
      }, function errorCallback() {
        $scope.appState = 'error';
        $scope.contactSupport = true;
        $scope.errorStatus = 'Unable to obtain course settings.';
      }
    );
  };

  // Switches to 'selection' step and scrolls to top of page
  $scope.switchToSelection = function() {
    apiService.util.iframeScrollToTop();
    $scope.appState = 'selection';
    $scope.focusOnSelectionHeader = true;
  };

  // Triggers auto-download of selected CSV download
  var downloadGrades = function() {
    var pnpCutoff = $scope.enablePnpConversion === 'false' ? 'ignore' : encodeURIComponent($scope.selectedPnpCutoffGrade);
    var downloadPath = [
      '/api/academics/canvas/egrade_export/download/',
      $scope.canvasCourseId + '.csv?',
      'ccn=' + $scope.selectedSection.course_cntl_num + '&',
      'term_cd=' + $scope.selectedSection.term_cd + '&',
      'term_yr=' + $scope.selectedSection.term_yr + '&',
      'type=' + $scope.selectedType + '&',
      'pnp_cutoff=' + pnpCutoff
    ].join('');
    $window.location.href = downloadPath;
  };

  // Performs authorization check on user to control interface presentation
  var checkAuthorization = function() {
    canvasSharedFactory.courseUserRoles($scope.canvasCourseId).then(
      function successCallback(response) {
        $scope.canvasRootUrl = response.data.canvasRootUrl;
        $scope.canvasCourseId = response.data.courseId;
        $scope.courseUserRoles = response.data.roles;

        $scope.userAuthorized = userIsAuthorized($scope.courseUserRoles);
        if ($scope.userAuthorized) {
          $scope.getExportOptions();
        } else {
          $scope.appState = 'error';
          $scope.errorStatus = 'You must be a teacher in this bCourses course to export to E-Grades CSV.';
        }
      },
      function errorCallback(response) {
        $scope.userAuthorized = false;
        $scope.appState = 'error';
        if (response.data && response.data.error) {
          $scope.errorStatus = response.data.error;
        } else {
          $scope.errorStatus = 'Authorization Check Failed';
          $scope.contactSupport = true;
        }
      }
    );
  };

  // Load and initialize application based on section terms provided
  var loadSectionTerms = function(sectionTerms) {
    if (sectionTerms && sectionTerms.length > 0) {
      $scope.sectionTerms = sectionTerms;

      if ($scope.sectionTerms.length > 1) {
        $scope.appState = 'error';
        $scope.errorStatus = 'This course site contains sections from multiple terms. Only sections from a single term should be present.';
        $scope.contactSupport = true;
      }
    } else {
      $scope.appState = 'error';
      $scope.errorStatus = 'No sections found in this course representing a currently maintained campus term.';
      $scope.unexpectedContactSupport = true;
    }
  };

  // Load and initialize application based on official sections
  var loadOfficialSections = function(officialSections) {
    if (officialSections && officialSections.length > 0) {
      $scope.officialSections = officialSections;
      $scope.selectedSection = $scope.officialSections[0];
    } else {
      $scope.appState = 'error';
      $scope.errorStatus = 'None of the sections within this course site are associated with UC Berkeley course catalog sections.';
      $scope.contactSupport = true;
    }
  };

  var userIsAuthorized = function(courseUserRoles) {
    var authorizedRoles = ['globalAdmin', 'Teacher'];
    return authorizedRoles.some(function(authorizedRole) {
      return courseUserRoles.indexOf(authorizedRole) > -1;
    });
  };

  checkAuthorization();
});
