<template>
  <div class="bc-canvas-application bc-page-course-grade-export">
    <div v-if="appState === 'initializing'" class="cc-spinner"></div>

    <div v-if="appState === 'error'">
      <div v-if="errorStatus" role="alert">
        <p>
          <fa icon="exclamation-triangle" class="text-warning"></fa> {{ errorStatus }}
        </p>
        <p v-if="showRetryOption"><a @click="retrySelection">Retry</a></p>
        <p v-if="contactSupport">If this is not expected, please contact <OutboundLink href="http://www.ets.berkeley.edu/discover-services/bcourses">bCourses support</OutboundLink> for further assistance.</p>
      </div>
    </div>

    <b-container v-if="appState === 'preselection'">
      <b-row no-gutters>
        <b-col md="12">
          <div>
            <fa icon="angle-left" class="cc-icon bc-template-back-icon mr-2"></fa>
            <a class="bc-template-back-link" :href="`/courses/${canvasCourseId}/grades`" target="_top">Back to Gradebook</a>
          </div>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col md="12">
          <h1 class="bc-page-course-grade-export-header">Before exporting your E-Grades:</h1>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col md="12">
          <h2 class="bc-page-course-grade-export-sub-header">1. Select a grading scheme:</h2>
          <p v-if="!noGradingStandardEnabled" class="bc-page-course-grade-export-download-description">
            You have already set a grading scheme. You can view your grading scheme or select an alternate grading scheme in
            <a :href="`/courses/${canvasCourseId}/settings#tab-details`" target="_top">Course Settings</a>.
          </p>
          <p v-if="noGradingStandardEnabled" class="bc-page-course-grade-export-download-description">
            Set a grading scheme in
            <a :href="`/courses/${canvasCourseId}/settings#tab-details`" target="_top">Course Settings</a>
            and return once completed.
          </p>
          <p class="bc-page-course-grade-export-download-description">
            For detailed instructions, see: "<OutboundLink href="https://community.canvaslms.com/docs/DOC-26521-how-do-i-enable-a-grading-scheme-for-a-course">How do I enable a grading scheme for a course?</OutboundLink>"
          </p>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col md="12">
          <h2 class="bc-page-course-grade-export-sub-header">2. Post all assignment grades:</h2>
          <p class="bc-page-course-grade-export-download-description">
            All assignment grades must be posted (published/unmuted) to ensure that your E-Grades export matches what you see in the gradebook. To confirm that all grades have been posted, review all columns in
            <a :href="`/courses/${canvasCourseId}/grades`" target="_top">your gradebook</a>
            for any assignments with a crossed-out eye icon
            <span class="cc-nowrap">
              (<img class="bc-page-course-grade-export-image-inline" src="@/assets/images/canvas/crossed_out_eye.png" alt="Crossed-out eye icon">)
            </span>
            indicating that an assignment has unposted grades.
          </p>
          <p class="bc-page-course-grade-export-download-description">
            To post unposted grades:
          </p>
          <ul class="bc-page-course-grade-export-download-list">
            <li>
              Mouse over the assignment name and select the three vertical dot menu
              <span class="cc-nowrap">(<img class="bc-page-course-grade-export-image-inline" src="@/assets/images/canvas/three_vertical_dots.png" alt="Three vertical dots">)</span>
            </li>
            <li>Select "Post grades"</li>
            <li>Select whether you wish to post grades for "Everyone," or only "Graded" students and click "Post"</li>
          </ul>
          <p class="bc-page-course-grade-export-download-description">
            For detailed instructions, see:
            "<OutboundLink href="https://community.canvaslms.com/docs/DOC-17330-41521116619">How do I post grades for an assignment?</OutboundLink>"
          </p>
          <p class="bc-page-course-grade-export-download-description">
            <strong>In order to avoid errors, we suggest cross-checking final grades in the bCourses gradebook with the output CSV to confirm grades were exported as expected.</strong>
          </p>
          <p class="bc-page-course-grade-export-download-description">
            If you have used the <OutboundLink href="https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-override-a-student-s-final-grade-in-the-Gradebook/ta-p/946">Final Grade Override</OutboundLink> feature to set student grades, the override grades will be included in the export.
          </p>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col md="12">
          <div class="cc-text-right">
            <button
              id="cancel-button"
              type="button"
              class="bc-canvas-button"
              aria-label="Go Back to Gradebook"
              @click="goToGradebook"
            >
              Cancel
            </button>
            <button
              id="continue-button"
              type="button"
              class="bc-canvas-button bc-canvas-button-primary"
              :disabled="noGradingStandardEnabled"
              @click="switchToSelection"
            >
              Continue
            </button>
          </div>
        </b-col>
      </b-row>
    </b-container>

    <b-container v-if="appState === 'selection'">
      <b-row no-gutters aria-hidden="true">
        <b-col md="12">
          <fa icon="angle-left" class="bc-template-back-icon cc-icon mr-2"></fa>
          <a class="bc-template-back-link" :href="`/courses/${canvasCourseId}/grades`" target="_top">Back to Gradebook</a>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col md="12">
          <h1
            id="bc-page-course-grade-export-header"
            class="bc-page-course-grade-export-header bc-accessibility-no-outline"
            tabindex="-1"
          >
            Export E-Grades
          </h1>
        </b-col>
      </b-row>
      <b-row class="cc-visuallyhidden">
        <a :href="`/courses/${canvasCourseId}/grades`" target="_top">Back to Gradebook</a>
      </b-row>
      <b-row v-if="officialSections.length > 1" no-gutters>
        <h2 class="bc-page-course-grade-export-download-header">Select section</h2>
      </b-row>
      <b-row v-if="officialSections.length > 1" no-gutters>
        <b-col md="5">
          <select id="course-sections" v-model="selectedSection" class="bc-form-input-select w-100">
            <option v-for="section in officialSections" :key="section.display_name" :value="section">
              {{ section.display_name }}
            </option>
          </select>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <h2 class="bc-page-course-grade-export-download-header">Configure P/NP grade options</h2>
      </b-row>
      <b-row no-gutters>
        <b-col md="5">
          <p class="bc-page-course-grade-export-download-description">
            <label for="input-enable-pnp-conversion-true">
              <input
                id="input-enable-pnp-conversion-true"
                v-model="enablePnpConversion"
                class="mr-2"
                type="radio"
                name="enablePnpCoversion"
                value="true"
                @change="selectedPnpCutoffGrade = ''"
              />
              Automatically convert letter grades in the E-Grades export to the student-selected grading option. Please select the lowest passing letter grade.
            </label>
          </p>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col md="5">
          <p class="bc-page-course-grade-export-download-description">
            <select
              id="select-pnp-grade-cutoff"
              v-model="selectedPnpCutoffGrade"
              class="bc-form-input-select bc-page-course-grade-export-select-pnp-cutoff"
              :disabled="enablePnpConversion !== 'true'"
            >
              <option value="">Select a grade</option>
              <option v-for="grade in letterGrades" :key="grade" :value="grade">
                {{ grade }}
              </option>
            </select>
          </p>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col md="5">
          <p class="bc-page-course-grade-export-download-description">
            <label for="input-enable-pnp-conversion-true">
              <input
                id="input-enable-pnp-conversion-false"
                v-model="enablePnpConversion"
                class="mr-2"
                type="radio"
                name="enablePnpConversion"
                value="false"
                @change="selectedPnpCutoffGrade = ''"
              />
              Do not automatically convert any letter grades to P/NP. I have applied a P/NP grading scheme to all grades in this course, or will manually adjust the grades in the E-Grades Export CSV to reflect the student-selected grading option.
            </label>
          </p>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <h2 class="bc-page-course-grade-export-download-header">What would you like to download?</h2>
      </b-row>
      <b-row no-gutters>
        <h3 class="bc-page-course-grade-export-download-header">Current Grades</h3>
      </b-row>
      <b-row no-gutters>
        <b-col md="5">
          <p class="bc-page-course-grade-export-download-description">
            Current grades download ignores unsubmitted assignments when calculating grades.
            Use this download when you want to excuse unsubmitted assignments.
          </p>
          <button
            id="download-current-grades-button"
            type="button"
            :disabled="enablePnpConversion !== 'false' && !selectedPnpCutoffGrade"
            class="bc-canvas-button bc-canvas-button-primary"
            @click="preloadGrades('current')"
          >
            Download Current Grades
          </button>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <h3 class="bc-page-course-grade-export-download-header">Final Grades</h3>
      </b-row>
      <b-row no-gutters>
        <b-col md="5">
          <p class="bc-page-course-grade-export-download-description">
            Final grades download counts unsubmitted assignments as zeroes when calculating grades.
            Use this download when you want to include all unsubmitted assignments as part of the grade.
          </p>
          <button
            id="download-final-grades-button"
            type="button"
            :disabled="enablePnpConversion !== 'false' && !selectedPnpCutoffGrade"
            class="bc-canvas-button bc-canvas-button-primary"
            @click="preloadGrades('final')"
          >
            Download Final Grades
          </button>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col md="12">
          <div class="bc-page-course-grade-export-more-info-container">
            <p class="bc-page-course-grade-export-more-info">
              For more information, see
              <OutboundLink href="https://berkeley.service-now.com/kb?id=kb_article_view&sysparm_article=KB0010659&sys_kb_id=8b7818e11b1837ccbc27feeccd4bcbbe">From bCourses to E-Grades</OutboundLink>
            </p>
          </div>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col v-if="canvasCourseId && canvasRootUrl" md="12" class="bc-page-course-grade-export-grade-link">
          <a :href="`/courses/${canvasCourseId}/grades`" target="_top">Back to Gradebook</a>
        </b-col>
      </b-row>
    </b-container>

    <div aria-live="polite">
      <b-container v-if="appState === 'loading'">
        <b-row no-gutters>
          <b-col md="5">
            <h1 class="bc-page-course-grade-export-header">Preparing E-Grades for Download</h1>
          </b-col>
        </b-row>
        <div v-if="!jobStatus" class="bc-page-course-grade-export-notice-pending-request">
          <fa icon="spinner" class="cc-icon fa-spin mr-2"></fa>
          Sending preparation request...
        </div>
        <div v-if="jobStatus === 'New'" class="bc-page-course-grade-export-notice-pending-request">
          <fa icon="spinner" class="cc-icon fa-spin mr-2"></fa>
          Preparation request sent. Awaiting processing....
        </div>
        <div v-if="jobStatus">
          <ProgressBar :percent-complete-rounded="percentCompleteRounded" />
        </div>
      </b-container>
    </div>
  </div>
</template>

<script>
import CanvasUtils from '@/mixins/CanvasUtils'
import Context from '@/mixins/Context'
import Iframe from '@/mixins/Iframe'
import OutboundLink from '@/components/util/OutboundLink'
import ProgressBar from '@/components/bcourses/shared/ProgressBar'
import {downloadGradeCsv, getCourseUserRoles, getExportJobStatus, getExportOptions, prepareGradesCacheJob} from '@/api/canvas'

export default {
  name: 'CourseGradeExport',
  components: { OutboundLink, ProgressBar },
  mixins: [CanvasUtils, Context, Iframe],
  data: () => ({
    appState: null,
    backgroundJobId: null,
    canvasCourseId: null,
    canvasRootUrl: null,
    contactSupport: false,
    courseUserRoles: [],
    enablePnpConversion: null,
    exportTimer: null,
    jobStatus: null,
    letterGrades: ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F'],
    noGradingStandardEnabled: false,
    officialSections: [],
    percentCompleteRounded: null,
    selectedPnpCutoffGrade: '',
    selectedSection: null,
    selectedType: null,
    showRetryOption: null
  }),
  methods: {
    downloadGrades() {
      const pnpCutoff = this.enablePnpConversion === 'false' ? 'ignore' : encodeURIComponent(this.selectedPnpCutoffGrade)
      downloadGradeCsv(
        this.canvasCourseId,
        this.selectedSection.course_cntl_num,
        this.selectedSection.term_cd,
        this.selectedSection.term_yr,
        this.selectedType,
        pnpCutoff
      )
    },
    goToGradebook() {
      const gradebookUrl = `${this.canvasRootUrl}/courses/${this.canvasCourseId}/grades`
      if (this.isInIframe) {
        this.iframeParentLocation(gradebookUrl)
      } else {
        window.location.href = gradebookUrl
      }
    },
    initializePnpCutoffGrades() {
      this.enablePnpConversion = 'true'
      this.selectedPnpCutoffGrade = ''
    },
    loadExportOptions() {
      getExportOptions(this.canvasCourseId).then(
        response => {
          this.loadSectionTerms(this.$_.get(response, 'sectionTerms'))
          if (this.appState !== 'error') {
            this.loadOfficialSections(this.$_.get(response, 'officialSections'))
          }
          if (this.appState !== 'error') {
            this.appState = 'preselection'
            if (!response.gradingStandardEnabled) {
              this.noGradingStandardEnabled = true
            }
            this.initializePnpCutoffGrades()
            this.$ready()
          }
        },
        this.$errorHandler
      )
    },
    loadOfficialSections(officialSections) {
      if (!officialSections || !officialSections.length) {
        this.appState = 'error'
        this.errorStatus = 'None of the sections within this course site are associated with UC Berkeley course catalog sections.'
        this.contactSupport = true
      } else {
        this.officialSections = officialSections
        this.selectedSection = officialSections[0]
      }
    },
    loadSectionTerms(sectionTerms) {
      if (!sectionTerms || !sectionTerms.length) {
        this.appState = 'error'
        this.errorStatus = 'No sections found in this course representing a currently maintained campus term.'
        this.contactSupport = true
      } else if (sectionTerms.length > 1) {
        this.appState = 'error'
        this.errorStatus = 'This course site contains sections from multiple terms. Only sections from a single term should be present.'
        this.contactSupport = true
      } else {
        this.sectionTerms = sectionTerms
      }
    },
    preloadGrades(type) {
      this.selectedType = type
      this.appState = 'loading'
      this.appfocus = true
      this.jobStatus = 'New'
      this.iframeScrollToTop()
      prepareGradesCacheJob(this.canvasCourseId).then(
        response => {
          if (response.jobRequestStatus === 'Success') {
            this.backgroundJobId = response.jobId
            this.startExportJob()
          } else {
            this.appState = 'error'
            this.errorStatus = 'Grade download request failed'
            this.showRetryOption = true
            this.contactSupport = false
          }
        },
        this.$errorHandler
      )
    },
    retrySelection() {
      this.appState = 'selection'
      this.contactSupport = false
      this.errorStatus = null
      this.showRetryOption = false
    },
    startExportJob() {
      this.exportTimer = setInterval(() => {
        getExportJobStatus(this.canvasCourseId, this.backgroundJobId).then(
          response => {
            this.jobStatus = response.jobStatus
            this.percentCompleteRounded = Math.round(response.percentComplete * 100)
            if (this.jobStatus !== 'New' && this.jobStatus !== 'Processing') {
              this.percentCompleteRounded = null
              clearInterval(this.exportTimer)
              this.alertScreenReader('Downloading export. Export form options presented for an additional download.')
              this.switchToSelection()
              this.downloadGrades()
            }
          },
          this.$errorHandler
        )
      }, 2000)
    },
    switchToSelection() {
      this.iframeScrollToTop()
      this.appState = 'selection'
      this.$putFocusNextTick('bc-page-course-grade-export-header')
    }
  },
  beforeDestroy() {
    clearInterval(this.exportTimer)
  },
  created() {
    this.appState = 'initializing'
    this.getCanvasCourseId()
    getCourseUserRoles(this.canvasCourseId).then(
      response => {
        this.canvasRootUrl = response.canvasRootUrl
        this.canvasCourseId = response.courseId
        if (this.$_.includes(response.roles, 'Teacher') || this.$_.includes(response.roles, 'globalAdmin') ) {
          this.loadExportOptions()
        } else {
          this.appState = 'error'
          this.errorStatus = 'You must be a teacher in this bCourses course to export to E-Grades CSV.'
        }
      },
      this.$errorHandler
    )
  }
}
</script>

<style scoped lang="scss">
.bc-page-course-grade-export {
  background-color: $bc-color-white;
  padding: 15px 25px;

  // Reset to avoid default Foundation form styling
  p {
    font-family: $bc-base-font-family;
    font-size: 14px;
    font-weight: 300;
    margin-bottom: 10px;
  }

  .bc-page-course-grade-export-button-link {
    font-weight: 300;
  }

  .bc-page-course-grade-export-header {
    font-family: $bc-base-font-family;
    font-size: 23px;
    font-weight: 400;
    padding: 12px 0 0;
  }

  .bc-page-course-grade-export-sub-header {
    font-family: $bc-base-font-family;
    font-size: 20px;
    font-weight: 400;
    margin: 15px 0;
  }

  .bc-page-course-grade-export-download-button-container {
    border: $bc-color-off-black 1px solid;
    margin: 10px;
  }

  .bc-page-course-grade-export-download-description {
    line-height: 18px;
    margin-bottom: 10px;
    padding: 4px 0;
  }

  .bc-page-course-grade-export-download-header {
    font-size: 20px;
    font-weight: 400;
    margin: 30px 0 5px;
  }

  .bc-page-course-grade-export-download-list {
    line-height: 18px;
    list-style-position: inside;
    list-style-type: disc;
    margin-bottom: 10px;
    padding: 4px 0;
  }

  .bc-page-course-grade-export-image-inline {
    height: 20px;
  }

  .bc-page-course-grade-export-more-info-container {
    margin-top: 40px;
  }

  .bc-page-course-grade-export-more-info {
    margin: 20px 0;
  }

  .bc-page-course-grade-export-section {
    margin: 10px 0;
  }

  .bc-page-course-grade-export-form-label {
    display: inline-block;
    margin: 8px 0;
  }

  .bc-page-course-grade-export-notice-pending-request {
    margin: 15px auto;
  }

  .bc-page-course-grade-export-refresh-button {
    font-size: 11px;
    padding: 1px 5px;
    text-decoration: none;
  }

  .bc-page-course-grade-export-select-pnp-cutoff {
    padding-right: 25px;
    width: fit-content;
  }
}
</style>
