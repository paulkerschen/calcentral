<template>
  <div class="bc-canvas-application bc-page-create-course-site p-5">
    <div v-if="!loading && !error" class="bc-accessibility-no-outline">
      <div v-if="isAdmin" class="bc-page-create-course-site-admin-options">
        <h1 class="cc-visuallyhidden">Administrator Options</h1>
        <button
          aria-controls="bc-page-create-course-site-admin-section-loader-form"
          class="bc-canvas-button bc-canvas-button-small bc-page-create-course-site-admin-mode-switch p-2"
          @click="adminMode = adminMode === 'act_as' ? 'by_ccn' : 'act_as'"
        >
          Switch to {{ adminMode === 'act_as' ? 'CCN input' : 'acting as instructor' }}
        </button>
        <div id="bc-page-create-course-site-admin-section-loader-form">
          <div v-if="adminMode === 'act_as'" class="pt-3">
            <h2 class="cc-visuallyhidden">Load Sections By Instructor UID</h2>
            <form class="bc-canvas-page-form bc-page-create-course-site-act-as-form" @submit="fetchFeed">
              <label for="instructor-uid" class="cc-visuallyhidden">Instructor UID</label>
              <b-form-input
                id="instructor-uid"
                v-model="adminActingAs"
                class="cc-left"
                placeholder="Instructor UID"
                type="text"
                role="search"
              ></b-form-input>
              <div class="pt-3">
                <button
                  class="bc-canvas-button bc-canvas-button-primary"
                  type="submit"
                  aria-label="Load official sections for instructor"
                  aria-controls="bc-page-create-course-site-steps-container"
                  @click="fetchFeed"
                >
                  As instructor
                </button>
              </div>
            </form>
          </div>
          <div v-if="adminMode === 'by_ccn'">
            <h2 class="cc-visuallyhidden">Load Sections By Course Control Numbers (CCN)</h2>
            <form class="bc-canvas-page-form" @submit="fetchFeed">
              <div v-if="$_.size(adminSemesters)">
                <div class="bc-buttonset">
                  <span v-for="(semester, index) in adminSemesters" :key="index">
                    <input
                      :id="`semester${index}`"
                      type="radio"
                      name="adminSemester"
                      class="cc-visuallyhidden"
                      :aria-selected="currentAdminSemester === semester.slug"
                      role="tab"
                      @click="switchAdminSemester(semester)"
                    />
                    <label
                      :for="`semester${index}`"
                      class="bc-buttonset-button"
                      role="button"
                      aria-disabled="false"
                      :class="{
                        'bc-buttonset-button-active': currentAdminSemester === semester.slug,
                        'bc-buttonset-corner-left': index === 0,
                        'bc-buttonset-corner-right': index === ($_.size(adminSemesters) - 1)
                      }"
                    >
                      {{ semester.name }}
                    </label>
                  </span>
                </div>
                <label
                  for="bc-page-create-course-site-ccn-list"
                  class="cc-visuallyhidden"
                >
                  Provide CCN List Separated by Commas or Spaces
                </label>
                <textarea
                  id="bc-page-create-course-site-ccn-list"
                  v-model="adminByCcns"
                  placeholder="Paste your list of CCNs here, separated by commas or spaces"
                >
                </textarea>
                <button
                  class="bc-canvas-button bc-canvas-button-primary"
                  type="submit"
                  aria-controls="bc-page-create-course-site-steps-container"
                >
                  Review matching CCNs
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
      <div v-if="showMaintenanceNotice" role="alert">
        <MaintenanceNotice />
      </div>
      <h1 class="bc-page-create-course-site-header bc-page-create-course-site-header1">Create a Course Site</h1>
      <div id="bc-page-create-course-site-steps-container" class="bc-page-create-course-site-steps-container">
        <div
          v-if="currentWorkflowStep === 'selecting'"
          id="bc-page-create-course-site-selecting-step"
          :aria-expanded="currentWorkflowStep === 'selecting'"
        >
          <!-- TODO: data-cc-spinner-directive -->
          <div data-cc-spinner-directive></div>
          <div v-if="!$_.size(teachingSemesters)" role="alert">
            <p>You are currently not listed as the instructor of record for any courses, so you cannot create a course site in bCourses.</p>
          </div>
          <div v-if="$_.size(teachingSemesters)">
            <div class="row collapse">
              <div class="medium-5 columns">
                <div class="bc-buttonset">
                  <!-- TODO: data-cc-focus-reset-directive -->
                  <h2
                    class="bc-page-create-course-site-header bc-page-create-course-site-header2 bc-accessibility-no-outline"
                    data-cc-focus-reset-directive="selectFocus"
                  >
                    Term
                  </h2>
                  <span v-for="(semester, index) in teachingSemesters" :key="index">
                    <input
                      :id="`semester${index}`"
                      type="radio"
                      name="semester"
                      class="cc-visuallyhidden"
                      :aria-selected="currentSemester === semester.slug"
                      role="tab"
                      @click="switchSemester(semester)"
                    />
                    <label
                      :for="`semester${index}`"
                      class="bc-buttonset-button"
                      aria-disabled="false"
                      :class="{
                        'bc-buttonset-button-active': currentSemester === semester.slug,
                        'bc-buttonset-corner-left': !index,
                        'bc-buttonset-corner-right': (index === $_.size(teachingSemesters) - 1)
                      }"
                    >
                      {{ semester.name }}
                    </label>
                  </span>
                </div>
              </div>
            </div>
            <div class="row collapse">
              <div class="medium-12 columns">
                <h2 class="bc-page-create-course-site-header bc-page-create-course-site-header2">Official Sections</h2>
                <p>All official sections you select below will be put in ONE, single course site.</p>
                <div class="bc-page-help-notice bc-page-create-course-site-help-notice">
                  <fa icon="question-circle" class="cc-left bc-page-help-notice-icon"></fa>
                  <div class="bc-page-help-notice-left-margin">
                    <button
                      class="bc-button-link"
                      aria-haspopup="true"
                      aria-controls="section-selection-help"
                      :aria-expanded="toggle.displayHelp"
                      @click="toggle.displayHelp = !toggle.displayHelp"
                    >
                      Need help deciding which official sections to select?
                    </button>
                    <div aria-live="polite">
                      <div
                        v-if="toggle.displayHelp"
                        id="section-selection-help"
                        class="bc-page-help-notice-content"
                      >
                        <p>If you have a course with multiple sections, you will need to decide whether you want to:</p>
                        <ol class="bc-page-create-course-site-help-notice-ordered-list">
                          <li>
                            Create one, single course site which includes official sections for both your primary and secondary sections, or
                          </li>
                          <li>
                            Create multiple course sites, perhaps with one for each section, or
                          </li>
                          <li>
                            Create separate course sites based on instruction mode.
                            <a target="_blank" href="https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0010732#instructionmode">
                              Learn more about instruction modes in bCourses.
                            </a>
                          </li>
                        </ol>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="row collapse">
              <div class="medium-12 columns">
                <form class="bc-canvas-page-form" @submit="showConfirmation">
                  <ul class="bc-page-create-course-site-section-margin">
                    <li v-for="course in coursesList" :key="course.course_id" class="bc-sections-course-container bc-sections-course-container-bottom-margin">
                      <button
                        type="button"
                        class="bc-button-link bc-page-create-course-site-form-course-button"
                        :aria-controls="course.course_id"
                        :aria-label="`Toggle course sections list for ${course.course_code} ${course.title}`"
                        :aria-expanded="!course.collapsed"
                        @click="course.collapsed = !course.collapsed"
                      >
                        <fa :icon="course.collapsed ? 'caret-right' : 'caret-down'" class="cc-left bc-sections-triangle-icon"></fa>
                        <h3 class="bc-sections-course-title">
                          {{ course.course_code }}
                          <span v-if="course.title"> : {{ course.title }}</span>
                        </h3>
                        <span v-if="$_.size(course.sections)">
                          ({{ pluralize('section', course.sections.length, {'one': '1', 'other': 'No'}) }})
                        </span>
                      </button>
                      <div
                        v-if="!course.collapsed"
                        :id="course.course_id"
                        class="bc-page-create-course-site-form-collapsible-container"
                        :aria-expanded="!course.collapsed"
                        role="region"
                      >
                        <div v-if="course.sections.length > 1" class="bc-page-create-course-site-form-select-all-option">
                          Select:
                          <button
                            :aria-label="`Select ${course.selectToggleText} of the course sections`"
                            class="bc-button-link bc-page-create-course-site-form-select-all-option-button"
                            type="button"
                            @click="toggleCourseSectionsWithUpdate(course)"
                          >
                            {{ course.selectToggleText }}
                          </button>
                        </div>
                        <!-- TODO: data-bc-sections-table -->
                        <div
                          data-bc-sections-table
                          data-list-mode="'createCourseForm'"
                          data-sections-list="course.sections"
                          data-row-display-logic="rowDisplayLogic()"
                          data-update-selected="updateSelected()"
                        ></div>
                      </div>
                    </li>
                  </ul>
                  <div class="bc-form-actions">
                    <button
                      class="bc-canvas-button bc-canvas-button-primary"
                      type="submit"
                      :disabled="!selectedSectionsList.length"
                      aria-controls="bc-page-create-course-site-steps-container"
                      aria-label="Continue to next step"
                      role="button"
                    >
                      Next
                    </button>
                    <a
                      :href="linkToSiteOverview"
                      class="bc-canvas-button"
                      type="reset"
                      aria-label="Cancel and return to Site Creation Overview"
                    >
                      Cancel
                    </a>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
        <div
          v-if="currentWorkflowStep === 'confirmation'"
          id="bc-page-create-course-site-confirmation-step"
          :aria-expanded="currentWorkflowStep === 'confirmation'"
        >
          <div class="row collapse">
            <div class="medium-12 columns">
              <div class="bc-alert bc-alert-info" role="alert">
                <!-- TODO: data-cc-focus-reset-directive -->
                <h2 class="cc-visuallyhidden" data-cc-focus-reset-directive="confirmFocus">Confirm Course Site Details</h2>
                <strong>
                  You are about to create a {{ currentSemesterName }} course site with
                  {{ selectedSections(coursesList).length }}
                  {{ pluralize(section, selectedSections(coursesList).length) }}:
                </strong>
                <ul class="bc-page-create-course-site-section-list">
                  <li v-for="section in selectedSections(coursesList)" :key="section.ccn">
                    {{ section.courseTitle }} - {{ section.courseCode }}
                    {{ section.section_label }} ({{ section.ccn }})
                  </li>
                </ul>
              </div>
            </div>
          </div>
          <div class="row collapse">
            <div class="medium-12 columns">
              <form
                name="createCourseSiteForm"
                class="bc-canvas-page-form"
                @submit="createCourseSiteJob"
              >
                <div class="row">
                  <div class="small-12 medium-6 end">
                    <div class="bc-page-create-course-site-form-fields-container">
                      <div class="row">
                        <div class="medium-offset-1 medium-4 columns">
                          <label for="siteName" class="right">Site Name:</label>
                        </div>
                        <div class="medium-7 columns">
                          <b-form-input
                            id="siteName"
                            v-model="siteName"
                            type="text"
                            name="siteName"
                            :required="true"
                          />
                          <div v-if="createCourseSiteForm.siteName.$error.required" class="bc-alert bc-notice-error">
                            <fa icon="exclamation-circle" class="cc-left cc-icon-red bc-canvas-notice-icon"></fa>
                            Please fill out a site name.
                          </div>
                        </div>
                      </div>
                      <div class="row">
                        <div class="medium-offset-1 medium-4 columns">
                          <label for="siteAbbreviation" class="right">Site Abbreviation:</label>
                        </div>
                        <div class="medium-7 columns">
                          <b-form-input
                            id="siteAbbreviation"
                            v-model="siteAbbreviation"
                            type="text"
                            name="siteAbbreviation"
                            :required="true"
                          />
                          <div v-if="createCourseSiteForm.siteAbbreviation.$error.required" class="bc-alert bc-notice-error">
                            <fa icon="exclamation-circle" class="cc-left cc-icon-red bc-canvas-notice-icon"></fa>
                            Please fill out a site abbreviation.
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="row">
                  <div class="medium-12 columns">
                    <div class="bc-form-actions">
                      <button
                        :disabled="createCourseSiteForm.$invalid"
                        class="bc-canvas-button bc-canvas-button-primary"
                        type="submit"
                        role="button"
                        aria-label="Create Course Site"
                        aria-controls="bc-page-create-course-site-steps-container"
                      >
                        Create Course Site
                      </button>
                      <button class="bc-canvas-button" type="button" @click="showSelecting">Go Back</button>
                    </div>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </div>
        <div
          v-if="currentWorkflowStep === 'monitoring_job'"
          id="bc-page-create-course-site-monitor-step"
          :aria-expanded="currentWorkflowStep === 'monitoring_job'"
        >
          <!-- TODO: data-cc-focus-reset-directive -->
          <h2 class="cc-visuallyhidden" data-cc-focus-reset-directive="confirmFocus">Course Site Creation</h2>
          <div aria-live="polite">
            <!-- TODO: data-ng-hide -->
            <div data-ng-hide="jobStatus" class="bc-page-create-course-site-pending-request">
              <fa icon="spinner" spin></fa>
              Sending request...
            </div>
            <div v-if="jobStatus === 'New'" class="bc-page-create-course-site-pending-request">
              <fa icon="spinner" spin></fa>
              Course provisioning request sent. Awaiting processing....
            </div>
            <div v-if="jobStatus">
              <div>
                <ProgressBar :percent-complete-rounded="50" />
              </div>
              <div v-if="jobStatus === 'Error'">
                <BackgroundJobError :error-config="errorConfig" :errors="errors" />
                <div class="row bc-page-create-course-site-step-options">
                  <div class="medium-12 columns">
                    <div class="bc-form-actions">
                      <button
                        class="bc-canvas-button bc-canvas-button-primary"
                        type="button"
                        aria-control="bc-page-create-course-site-selecting-step"
                        aria-label="Start over course site creation process"
                        @click="fetchFeed"
                      >
                        Start Over
                      </button>
                      <button
                        class="cc-button cc-page-button-grey"
                        type="button"
                        aria-control="bc-page-create-course-site-confirmation-step"
                        aria-label="Go Back to Site Details Confirmation"
                        @click="showConfirmation"
                      >
                        Back
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-if="jobStatus === 'Completed'" :aria-expanded="jobStatus === 'Completed'">
            <!-- TODO: data-cc-spinner-directive -->
            <div data-cc-spinner-directive></div>
            <div class="cc-visuallyhidden" role="alert">
              Redirecting to new course site.
            </div>
          </div>
        </div>
      </div>
    </div>
    <div v-if="error" class="bc-alert-container pt-5">
      <CanvasErrors :message="error" />
    </div>
  </div>
</template>

<script>
import BackgroundJobError from '@/components/bcourses/shared/BackgroundJobError'
import CanvasErrors from '@/components/bcourses/CanvasErrors'
import Context from '@/mixins/Context'
import MaintenanceNotice from '@/components/bcourses/shared/MaintenanceNotice'
import ProgressBar from '@/components/bcourses/shared/ProgressBar'
import Utils from '@/mixins/Utils'
import {getCourseProvisioningMetadata, getSections} from '@/api/canvas'

export default {
  name: 'CreateCourseSite',
  mixins: [Context, Utils],
  components: {BackgroundJobError, CanvasErrors, MaintenanceNotice, ProgressBar},
  data: () => ({
    adminActingAs: undefined,
    adminByCcns: undefined,
    adminMode: 'act_as',
    adminSemesters: undefined,
    canvasCourseId: undefined,
    course: undefined,
    coursesList: undefined,
    currentAdminSemester: undefined,
    currentSemester: undefined,
    currentSemesterName: undefined,
    currentWorkflowStep: undefined,
    errorConfig: {
      header: undefined,
      supportAction: undefined,
      supportInfo: undefined
    },
    error: undefined,
    errors: undefined,
    isAdmin: undefined,
    isTeacher: undefined,
    isUidInputMode: true,
    jobStatus: undefined,
    linkToSiteOverview: undefined,
    selectedSectionsList: undefined,
    semester: undefined,
    showMaintenanceNotice: true,
    siteName: undefined,
    teachingSemesters: undefined,
    toggle: {
      displayHelp: false
    }
  }),
  mounted() {
    getCourseProvisioningMetadata().then(data => {
      this.adminActingAs = data.admin_acting_as
      this.adminSemesters = data.admin_semesters
      this.isAdmin = data.is_admin
      this.teachingSemesters = data.teachingSemesters
      this.$ready()
    })
  },
  methods: {
    classCount(semesters) {
      let count = 0
      if (this.$_.size(semesters) > 0) {
        this.$_.each(semesters, semester => {
          count += semester.classes.length
        })
      }
      return count
    },
    clearCourseSiteJob() {
      this.jobId = undefined
      this.jobStatus = undefined
      this.completedSteps = undefined
      this.percentComplete = undefined
      this.showMaintenanceNotice = true
    },
    createCourseSiteJob() {
      this.showMaintenanceNotice = false
      // TODO
    },
    fetchFeed() {
      this.clearCourseSiteJob()
      this.$loading()
      this.feedFetched = false
      this.currentWorkflowStep = 'selecting'
      this.selectedSectionsList = []
      this.accessibilityAnnounce('Loading courses and sections')
      getSections(
        this.adminActingAs,
        this.adminByCcns,
        this.adminMode,
        this.currentAdminSemester,
        this.isAdmin
      ).then(data => {
        data.usersClassCount = this.classCount(data.teachingSemesters)
        const canvasCourseId = data.canvas_course ? data.canvas_course.canvasCourseId : ''
        this.fillCourseSites(data.teachingSemesters, canvasCourseId)
        this.feedFetched = true
        this.selectFocus = true
        // TODO: Error handling?
        // if (this.sectionsFeed.status !== 200) {
        //   $scope.accessibilityAnnounce('Course section loading failed');
        //   $scope.isLoading = false;
        //   $scope.displayError = 'failure';
        // } else {
        this.accessibilityAnnounce('Course section loaded successfully')
        if (this.$_.size(this.teachingSemesters) > 0) {
          this.switchSemester(this.teachingSemesters[0])
        }
        if (!this.currentAdminSemester && this.$_.size(this.adminSemesters) > 0) {
          this.switchAdminSemester(this.adminSemesters[0])
        }
        if (this.adminMode === 'by_ccn' && this.adminByCcns) {
          this.selectAllSections()
        }
        if (!this.isAdmin && !this.usersClassCount) {
          this.displayError = 'Sorry, you are not an admin user and you have no classes.'
        }
      })
    },
    fillCourseSites(semestersFeed, canvasCourseId) {
      this.$_.each(semestersFeed, semester => {
        this.$_.each(semester.classes, course => {
          course.collapsed = !course.containsCourseSections
          course.allSelected = false
          course.selectToggleText = 'All'
          let hasSites = false
          let ccnToSites = {}
          this.$_.each(course.class_sites, site => {
            if (site.emitter === 'bCourses') {
              if (site.id !== canvasCourseId) {
                this.$_.each(site.sections, siteSection => {
                  hasSites = true
                  if (!ccnToSites[siteSection.ccn]) {
                    ccnToSites[siteSection.ccn] = []
                  }
                  ccnToSites[siteSection.ccn].push(site)
                })
              }
            }
          })
          if (hasSites) {
            course.hasSites = hasSites
            this.$_.each(course.sections, section => {
              let ccn = section.ccn
              if (ccnToSites[ccn]) {
                section.sites = ccnToSites[ccn]
              }
            })
          }
        })
      })
    },
    loadCourseLists() {
      this.courseSemester = false
      // identify semester matching current course site
      this.$_.each(this.teachingSemesters, semester => {
        if ((semester.termYear === this.canvasCourse.term.term_yr) && (semester.termCode === this.canvasCourse.term.term_cd)) {
          this.courseSemester = semester
        }
      })
      if (this.courseSemester) {
        // count classes only in course semester to determine authorization to use this tool
        this.usersClassCount = this.courseSemester.classes.length

        // generate list of existing course sections for preview table
        // and flattened array of all sections for current sections staging table
        this.existingCourseSections = []
        this.allSections = []
        const existingCcns = []
        this.$_.each(this.courseSemester.classes, classItem => {
          this.$_.each(classItem.sections, section => {
            section.parentClass = classItem
            this.allSections.push(section)
            section.stagedState = null
            this.$_.each(this.canvasCourse.officialSections, officialSection => {
              if (officialSection.ccn === section.ccn && existingCcns.indexOf(section.ccn) === -1) {
                existingCcns.push(section.ccn)
                this.existingCourseSections.push(section)
                if (officialSection.name !== `${section.courseCode} ${section.section_label}`) {
                  section.nameDiscrepancy = true
                }
              }
            })
          })
        })
      } else {
        this.usersClassCount = 0
      }
    },
    selectedSections(coursesList) {
      const selectedSections = []
      this.$_.each(coursesList, course => {
        this.$_.each(course.sections, section => {
          if (section.selected) {
            section.courseTitle = course.title
            section.courseCatalog = course.course_catalog
            selectedSections.push(section)
          }
        })
      })
      return selectedSections
    },
    selectAllSections() {
      const newSelectedCourses = []
      this.$_.each(this.coursesList, course => {
        this.$_.each(course.sections, section => {
          section.selected = true
        })
        newSelectedCourses.push(course)
      })
      this.coursesList = newSelectedCourses
      this.updateSelected()
    },
    showConfirmation() {
      // TODO
      return []
    },
    showSelecting() {
      // TODO
      return false
    },
    switchAdminSemester(semester) {
      this.currentAdminSemester = semester.slug
      this.selectedSectionsList = []
      this.updateSelected()

    },
    switchSemester(semester) {
      this.currentSemester = semester.slug
      this.coursesList = semester.classes
      this.selectedSectionsList = []
      this.currentSemesterName = semester.name
      this.accessibilityAnnounce(`'Course sections for ${semester.name} loaded'`)
      this.updateSelected()
    },
    toggleCourseSectionsWithUpdate() {
      // TODO
    },
    updateSelected() {
      this.selectedSectionsList = this.selectedSections(this.coursesList)
    }
  }
}
</script>
