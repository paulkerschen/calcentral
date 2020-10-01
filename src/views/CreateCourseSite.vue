<template>
  <div class="bc-canvas-application bc-page-create-course-site">
    <div v-if="!loading && !errorType" class="bc-accessibility-no-outline">
      <div v-if="isAdmin" class="bc-page-create-course-site-admin-options">
        <h1 class="cc-visuallyhidden">Administrator Options</h1>
        <button
          aria-controls="bc-page-create-course-site-admin-section-loader-form"
          class="bc-canvas-button bc-canvas-button-small bc-page-create-course-site-admin-mode-switch"
          @click="isUidInputMode = !isUidInputMode"
        >
          Switch to {{ isUidInputMode ? 'acting as instructor' : 'CCN input' }}
        </button>
        <div id="bc-page-create-course-site-admin-section-loader-form">
          <div v-if="isUidInputMode">
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
              <button
                class="bc-canvas-button bc-canvas-button-primary"
                type="submit"
                aria-label="Load official sections for instructor"
                aria-controls="bc-page-create-course-site-steps-container"
              >
                As instructor
              </button>
            </form>
          </div>
          <div v-if="!isUidInputMode">
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
    <div v-if="errorType" class="bc-alert-container">
      <CanvasErrors :display-error="errorType" />
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
import {getCourseSections} from '@/api/canvas'

export default {
  name: 'CreateCourseSite',
  mixins: [Context, Utils],
  components: {BackgroundJobError, CanvasErrors, MaintenanceNotice, ProgressBar},
  data: () => ({
    adminActingAs: undefined,
    adminByCcns: undefined,
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
    errors: undefined,
    errorType: undefined,
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
    this.canvasCourseId = this.isInIframe ? 'embedded' : this.$route.query.canvasCourseId
    if (this.canvasCourseId) {
      getCourseSections(this.canvasCourseId).then(data => {
        this.percentCompleteRounded = undefined
        // get users feed
        if (data) {
          if (data.canvas_course) {
            this.canvasCourse = data.canvas_course
            this.isTeacher = this.canvasCourse.canEdit
            if (data.teachingSemesters) {
              this.loadCourseLists(data.teachingSemesters)
            }
            this.isAdmin = data.is_admin
            this.adminActingAs = data.admin_acting_as
            this.adminSemesters = data.admin_semesters
            this.isCourseCreator = this.usersClassCount > 0
            this.feedFetched = true
            this.currentWorkflowStep = 'preview'
          } else {
            this.errorType = 'failure'
          }
        } else {
          this.errorType = 'failure'
        }
        this.$ready()
      })
    } else {
      this.errorType = 'badRequest'
    }
  },
  methods: {
    createCourseSiteJob() {
      this.showMaintenanceNotice = false
      // TODO
    },
    fetchFeed() {
      // TODO
      return []
    },
    selectedSections(coursesList) {
      // TODO
      console.log(coursesList)
      return []
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
      // TODO
      console.log(semester)
    },
    switchSemester(semester) {
      // TODO
      console.log(semester)
    },
    toggleCourseSectionsWithUpdate() {
      // TODO
    },
    loadCourseLists(teachingSemesters) {
      this.courseSemester = false
      // identify semester matching current course site
      this.$_.each(teachingSemesters, semester => {
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
    }
  }
}
</script>
