<template>
  <div class="bc-canvas-application bc-page-create-course-site pl-5 pr-5 pt-3 pb-3">
    <div v-if="loading" class="cc-spinner"></div>
    <div v-if="!loading && !displayError" class="bc-accessibility-no-outline">
      <div class="d-flex flex-column pt-3">
        <div>
          <div v-if="showMaintenanceNotice" role="alert">
            <MaintenanceNotice course-action-verb="site is created" />
          </div>
        </div>
        <div>
          <h1 class="bc-page-create-course-site-header bc-page-create-course-site-header1">Create a Course Site</h1>
        </div>
        <div>
          <CreateCourseSiteHeader
            v-if="isAdmin && currentWorkflowStep !== 'monitoring_job'"
            :admin-mode="adminMode"
            :admin-semesters="adminSemesters"
            :current-admin-semester="currentAdminSemester"
            :fetch-feed="fetchFeed"
            :set-admin-acting-as="setAdminActingAs"
            :set-admin-by-ccns="setAdminByCcns"
            :set-admin-mode="setAdminMode"
            :show-maintenance-notice="showMaintenanceNotice"
            :switch-admin-semester="switchAdminSemester"
          />
        </div>
      </div>
      <div v-if="isAdmin && !currentWorkflowStep">
        Use inputs above to choose courses by CCN or as an instructor. 
      </div>
      <div id="bc-page-create-course-site-steps-container" class="p-0">
        <div
          v-if="currentWorkflowStep === 'selecting'"
          id="bc-page-create-course-site-selecting-step"
          :aria-expanded="`${currentWorkflowStep === 'selecting'}`"
        >
          <SelectSectionsStep
            :courses-list="coursesList"
            :current-semester="currentSemester"
            :selected-sections-list="selectedSectionsList"
            :show-confirmation="showConfirmation"
            :switch-semester="switchSemester"
            :teaching-semesters="teachingSemesters"
            :update-selected="updateSelected"
          />
        </div>
        <div
          v-if="currentWorkflowStep === 'confirmation'"
          id="bc-page-create-course-site-confirmation-step"
          :aria-expanded="`${currentWorkflowStep === 'confirmation'}`"
        >
          <ConfirmationStep
            :start-course-site-job="startCourseSiteJob"
            :current-semester-name="currentSemesterName"
            :go-back="showSelecting"
            :selected-sections-list="selectedSectionsList"
          />
        </div>
        <div
          v-if="currentWorkflowStep === 'monitoring_job'"
          id="bc-page-create-course-site-monitor-step"
          :aria-expanded="`${currentWorkflowStep === 'monitoring_job'}`"
        >
          <MonitoringJob
            :fetch-feed="fetchFeed"
            :job-status="jobStatus"
            :percent-complete="percentComplete"
            :show-confirmation="showConfirmation"
          />
        </div>
      </div>
    </div>
    <div v-if="displayError" class="bc-alert-container pt-5">
      <CanvasErrors :message="displayError" />
    </div>
  </div>
</template>

<script>
import CanvasErrors from '@/components/bcourses/CanvasErrors'
import ConfirmationStep from '@/components/bcourses/create/ConfirmationStep'
import Context from '@/mixins/Context'
import CreateCourseSiteHeader from '@/components/bcourses/create/CreateCourseSiteHeader'
import Iframe from '@/mixins/Iframe'
import MaintenanceNotice from '@/components/bcourses/shared/MaintenanceNotice'
import MonitoringJob from '@/components/bcourses/create/MonitoringJob'
import SelectSectionsStep from '@/components/bcourses/create/SelectSectionsStep'
import Utils from '@/mixins/Utils'
import {courseCreate, courseProvisionJobStatus, getCourseProvisioningMetadata, getSections} from '@/api/canvas'

export default {
  name: 'CreateCourseSite',
  mixins: [Context, Iframe, Utils],
  components: {
    CanvasErrors,
    ConfirmationStep,
    CreateCourseSiteHeader,
    MaintenanceNotice,
    MonitoringJob,
    SelectSectionsStep
  },
  data: () => ({
    adminActingAs: undefined,
    adminByCcns: undefined,
    adminMode: 'act_as',
    adminSemesters: undefined,
    canvasCourse: undefined,
    canvasCourseId: undefined,
    course: undefined,
    coursesList: undefined,
    currentAdminSemester: undefined,
    currentSemester: undefined,
    currentSemesterName: undefined,
    currentWorkflowStep: undefined,
    displayError: undefined,
    errorConfig: {
      header: undefined,
      supportAction: undefined,
      supportInfo: undefined
    },
    isAdmin: undefined,
    isTeacher: undefined,
    isUidInputMode: true,
    jobStatus: undefined,
    percentComplete: undefined,
    selectedSectionsList: undefined,
    semester: undefined,
    showMaintenanceNotice: true,
    teachingSemesters: undefined,
    timeoutPromise: undefined
  }),
  created() {
    this.$loading()
    getCourseProvisioningMetadata().then(data => {
      this.updateMetadata(data)
      this.$ready('Create Canvas Course Site')
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
    fetchFeed() {
      this.clearCourseSiteJob()
      this.$loading()
      this.currentWorkflowStep = 'selecting'
      this.selectedSectionsList = []
      this.alertScreenReader('Loading courses and sections')

      const onSuccess = data => {
        this.updateMetadata(data)
        this.usersClassCount = this.classCount(data.teachingSemesters)
        this.teachingSemesters = data.teachingSemesters
        this.canvasCourse = data.canvas_course
        const canvasCourseId = this.canvasCourse ? this.canvasCourse.canvasCourseId : ''
        this.fillCourseSites(data.teachingSemesters, canvasCourseId)
        this.alertScreenReader('Course section loaded successfully')
        if (this.adminMode === 'by_ccn' && this.adminByCcns) {
          this.$_.each(this.coursesList, course => {
            this.$_.each(course.sections, section => {
              section.selected = this.$_.includes(this.adminByCcns, section.ccn)
            })
          })
          this.updateSelected()
        }
        if (!this.isAdmin && !this.usersClassCount) {
          this.displayError = 'Sorry, you are not an admin user and you have no classes.'
        }
        this.$ready()
      }

      const onError = data => {
        this.alertScreenReader('Course section loading failed')
        this.displayError = 'failure'
        this.$ready()
        return this.$errorHandler(data)
      }

      const semester = (this.adminMode === 'by_ccn' ? this.currentAdminSemester : this.currentSemester)

      getSections(
        this.adminActingAs,
        this.adminByCcns,
        this.adminMode,
        semester,
        this.isAdmin
      ).then(onSuccess, onError)
    },
    fillCourseSites(semestersFeed, canvasCourseId=null) {
      this.$_.each(semestersFeed, semester => {
        this.$_.each(semester.classes, course => {
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
    jobStatusLoader() {
      const onSuccess = data => {
        this.jobId = data.jobId
        this.jobStatus = data.jobStatus
        this.completedSteps = data.completedSteps
        this.percentComplete = data.percentComplete
        if (this.jobStatus === 'Processing' || this.jobStatus === 'New') {
          this.alertScreenReader(`${Math.round(this.percentComplete * 100)} percent done in creating new course site.`)
          this.jobStatusLoader()
        } else {
          clearTimeout(this.timeoutPromise)
          const courseSiteUrl =  this.$_.get(data.courseSite, 'url')
          if (this.jobStatus === 'Completed' && courseSiteUrl) {
            this.alertScreenReader('Done. Loading new course site now.')
            if (this.isInIframe) {
              this.iframeParentLocation(courseSiteUrl)
            } else {
              window.location.href = courseSiteUrl
            }
          } else {
            this.displayError = 'Failed to create course site.'
          }
        }
      }
      const onError = data => {
        this.alertScreenReader('Course section loading failed')
        this.displayError = 'failure'
        this.percentComplete = 0
        this.jobStatus = 'Error'
        this.displayError = 'Failed to create course provisioning job.'
        return this.$errorHandler(data)
      }
      const handler = () => courseProvisionJobStatus(this.jobId).then(onSuccess, onError)
      this.timeoutPromise = setTimeout(handler, 2000)
    },
    loadCourseLists() {
      this.courseSemester = false
      // identify semester matching current course site
      this.$_.each(this.teachingSemesters, semester => {
        if ((semester.termYear === this.canvasCourse.term.term_yr) && (semester.termCode === this.canvasCourse.term.term_cd)) {
          this.courseSemester = semester
          return false
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
      const selected = []
      this.$_.each(coursesList, course => {
        this.$_.each(course.sections, section => {
          if (section.selected) {
            section.courseTitle = course.title
            section.courseCatalog = course.course_catalog
            selected.push(section)
          }
        })
      })
      return selected
    },
    setAdminActingAs(uid) {
      this.adminActingAs = uid
      this.adminByCcns = null
    },
    setAdminByCcns(ccns) {
      this.adminByCcns = ccns
      this.adminActingAs = null
    },
    setAdminMode(adminMode) {
      this.adminMode = adminMode
      this.currentWorkflowStep = undefined
    },
    showConfirmation() {
      this.updateSelected()
      this.alertScreenReader('Course site details form loaded.')
      this.currentWorkflowStep = 'confirmation'
    },
    showSelecting() {
      this.currentWorkflowStep = 'selecting'
    },
    startCourseSiteJob(siteName, siteAbbreviation) {
      this.percentComplete = 0
      this.currentWorkflowStep = 'monitoring_job'
      this.alertScreenReader('Creating course site. Please wait.')
      this.showMaintenanceNotice = false
      this.updateSelected()
      const ccns = this.$_.map(this.selectedSectionsList, 'ccn')
      if (ccns.length > 0) {
        const onSuccess = data => {
          this.jobId = data.job_id
          this.currentWorkflowStep = 'monitoring_job'
          this.alertScreenReader('Started course site creation.')
          this.completedFocus = true
          this.jobStatusLoader()
        }
        const onError = error => {
          this.percentComplete = 0
          this.currentWorkflowStep = null
          this.jobStatus = 'Error'
          this.displayError = 'Failed to create course provisioning job.'
          return this.$errorHandler(error)
        }
        courseCreate(
          this.isAdmin && this.adminMode === 'act_as' ? this.adminActingAs : null,
          this.isAdmin && this.adminMode === 'by_ccn' ? this.adminByCcns : null,
          this.isAdmin && this.adminMode === 'by_ccn' ? this.currentAdminSemester : null,
          ccns,
          siteAbbreviation,
          siteName,
          this.currentSemester
        ).then(onSuccess, onError)
      }
    },
    switchAdminSemester(semester) {
      this.currentAdminSemester = semester.slug
      this.selectedSectionsList = []
      this.updateSelected()
      this.alertScreenReader(`Switched to ${semester.name} for CCN input`)
    },
    switchSemester(semester) {
      this.currentSemester = semester.slug
      this.coursesList = semester.classes
      this.selectedSectionsList = []
      this.currentSemesterName = semester.name
      this.alertScreenReader(`Course sections for ${semester.name} loaded`)
      this.updateSelected()
    },
    updateMetadata(data) {
      this.isAdmin = data.is_admin
      this.teachingSemesters = data.teachingSemesters
      if (this.$_.size(this.teachingSemesters) > 0) {
        this.switchSemester(this.teachingSemesters[0])
      }
      this.fillCourseSites(this.teachingSemesters)
      if (this.isAdmin) {
        this.adminActingAs = data.admin_acting_as
        this.adminSemesters = data.admin_semesters
        if (this.$_.size(this.adminSemesters) > 0 && !this.currentAdminSemester) {
          this.switchAdminSemester(this.adminSemesters[0])
        }
      } else {
        this.currentWorkflowStep = 'selecting'
      }
    },
    updateSelected() {
      this.selectedSectionsList = this.selectedSections(this.coursesList)
    }
  }
}
</script>

<style scoped lang="scss">
.bc-page-create-course-site {
  padding: 25px;

  .cc-button {
    padding: 10px;
  }
  .cc-page-button-grey {
    background: linear-gradient($bc-color-button-grey-gradient-1, $bc-color-button-grey-gradient-2);
    border: 1px solid $bc-color-button-grey-border;
    color: $bc-color-button-grey-text;
  }
  .bc-page-create-course-site-choices {
    overflow: hidden;
    li {
      border-left: 1px solid $cc-color-very-light-grey;
      float: left;
      max-width: 250px;
      padding: 15px;
      width: 50%;
      &:first-child {
        border: 0;
      }
    }
  }
  .bc-page-create-course-site-form-course-button {
    color: $bc-color-body-black;

    &:focus, &:hover {
      text-decoration: none;
    }
  }
  .bc-page-create-course-site-header {
    color: $bc-color-headers;
    font-family: $bc-base-font-family;
    font-weight: normal;
    line-height: 40px;
    margin: 5px 0;
  }
  .bc-page-create-course-site-header1 {
    font-size: 23px;
  }
}
</style>
