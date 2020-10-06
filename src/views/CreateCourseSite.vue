<template>
  <div class="bc-canvas-application bc-page-create-course-site p-5">
    <div v-if="!loading && !error" class="bc-accessibility-no-outline">
      <CreateCourseSiteHeader
        :set-admin-acting-as="setAdminActingAs"
        :admin-mode="adminMode"
        :admin-semesters="adminSemesters"
        :current-admin-semester="currentAdminSemester"
        :is-admin="isAdmin"
        :fetch-feed="fetchFeed"
        :set-admin-by-ccns="setAdminByCcns"
        :set-admin-mode="setAdminMode"
        :show-maintenance-notice="showMaintenanceNotice"
        :switch-admin-semester="switchAdminSemester"
      />
      <div id="bc-page-create-course-site-steps-container" class="p-0">
        <div
          v-if="currentWorkflowStep === 'selecting'"
          id="bc-page-create-course-site-selecting-step"
          :aria-expanded="currentWorkflowStep === 'selecting'"
        >
          <SelectSectionsStep
            :courses-list="coursesList"
            :current-semester="currentSemester"
            :selected-sections-list="selectedSectionsList"
            :show-confirmation="showConfirmation"
            :switch-semester="switchSemester"
            :teaching-semesters="teachingSemesters"
            :toggle-course-sections-with-update="toggleCourseSectionsWithUpdate"
            :update-selected="updateSelected"
          />
        </div>
        <div
          v-if="currentWorkflowStep === 'confirmation'"
          id="bc-page-create-course-site-confirmation-step"
          :aria-expanded="currentWorkflowStep === 'confirmation'"
        >
          <ConfirmationStep
            :create-course-site-job="createCourseSiteJob"
            :current-semester-name="currentSemesterName"
            :go-back="showSelecting"
            :selected-sections-list="selectedSectionsList"
          />
        </div>
        <div
          v-if="currentWorkflowStep === 'monitoring_job'"
          id="bc-page-create-course-site-monitor-step"
          :aria-expanded="currentWorkflowStep === 'monitoring_job'"
        >
          <MonitoringJob
            fetch-feed="fetchFeed"
            job-status="jobStatus"
            show-confirmation="showConfirmation"
          />
        </div>
      </div>
    </div>
    <div v-if="error" class="bc-alert-container pt-5">
      <CanvasErrors :message="error" />
    </div>
  </div>
</template>

<script>
import Accessibility from '@/mixins/Accessibility'
import CanvasErrors from '@/components/bcourses/CanvasErrors'
import ConfirmationStep from '@/components/bcourses/create/ConfirmationStep'
import Context from '@/mixins/Context'
import CreateCourseSiteHeader from '@/components/bcourses/create/CreateCourseSiteHeader'
import Iframe from '@/mixins/Iframe'
import MonitoringJob from '@/components/bcourses/create/MonitoringJob'
import SelectSectionsStep from '@/components/bcourses/create/SelectSectionsStep'
import Utils from '@/mixins/Utils'
import {courseCreate, courseProvisionJobStatus, getCourseProvisioningMetadata, getSections} from '@/api/canvas'

export default {
  name: 'CreateCourseSite',
  mixins: [Accessibility, Context, Iframe, Utils],
  components: {
    CanvasErrors,
    ConfirmationStep,
    CreateCourseSiteHeader,
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
    courseSite: undefined,
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
    percentComplete: undefined,
    percentCompleteRounded: undefined,
    selectedSectionsList: undefined,
    semester: undefined,
    showMaintenanceNotice: true,
    teachingSemesters: undefined,
    timeoutPromise: undefined
  }),
  created() {
    this.$loading()
    getCourseProvisioningMetadata().then(data => {
      this.adminActingAs = data.admin_acting_as
      this.adminSemesters = data.admin_semesters
      this.isAdmin = data.is_admin
      this.teachingSemesters = data.teachingSemesters
      this.$ready('Create a Course Site')
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
    createCourseSiteJob(siteName, siteAbbreviation) {
      this.currentWorkflowStep = 'monitoring_job'
      this.accessibilityAnnounce('Creating course site. Please wait.')
      this.monitorFocus = true
      this.showMaintenanceNotice = false
      this.updateSelected()
      const ccns = this.$_.map(this.selectedSectionsList, 'ccn')
      if (ccns.length > 0) {
        const course = {
          siteName,
          siteAbbreviation,
          'termSlug': this.currentSemester,
          'ccns': ccns
        }
        if (this.isAdmin) {
          if (this.adminMode !== 'by_ccn' && this.admin_acting_as) {
            course.admin_acting_as = this.admin_acting_as
          } else if (this.adminMode === 'by_ccn' && this.adminByCcns) {
            course.admin_by_ccns = this.admin_by_ccns.match(/\w+/g)
            course.admin_term_slug = this.currentAdminSemester
          }
        }
        courseCreate(course).then(data => {
          this.$_.assignIn(this, data)
          this.currentWorkflowStep = 'monitoring_job'
          this.accessibilityAnnounce('Course site created successfully')
          this.completedFocus = true
          this.jobStatusLoader()
        })
        // TODO: error handling
        //   function errorCallback() {
        //     this.$_.assignIn(this, {
        //       percentCompleteRounded: 0,
        //       currentWorkflowStep: 'monitoring_job',
        //       jobStatus: 'Error',
        //       error: 'Failed to create course provisioning job.'
        //     });
        //   }
      }
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
        this.teachingSemesters = data.teachingSemesters
        this.canvasCourse = data.canvas_course
        const canvasCourseId = this.canvasCourse ? this.canvasCourse.canvasCourseId : ''
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
        this.$ready()
      })
    },
    fillCourseSites(semestersFeed, canvasCourseId) {
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
      this.timeoutPromise = setTimeout(
        () => {
          return courseProvisionJobStatus(this.jobId).then(data => {
            this.$_.assignIn(this, data)
            this.percentCompleteRounded = Math.round(this.percentComplete * 100)
            if (this.jobStatus === 'Processing' || this.jobStatus === 'New') {
              this.jobStatusLoader()
            } else {
              this.$loading()
              this.percentCompleteRounded = undefined
              clearTimeout(this.timeoutPromise)
              if (this.jobStatus === 'Completed') {
                if (this.courseSite && this.courseSite.url) {
                  if (this.isInIframe) {
                    this.iframeParentLocation(this.courseSite.url)
                  } else {
                    window.location.href = this.courseSite.url
                  }
                } else {
                  this.displayError = 'failure'
                }
              }
            }
            // TODO: error handling
            //   this.displayError = 'failure'
            //
          })
        }, 2000)
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
      const selectedSectionsList = []
      this.$_.each(coursesList, course => {
        this.$_.each(course.sections, section => {
          if (section.selected) {
            section.courseTitle = course.title
            section.courseCatalog = course.course_catalog
            selectedSectionsList.push(section)
          }
        })
      })
      return selectedSectionsList
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
    setAdminActingAs(uid) {
      this.adminActingAs = uid
    },
    setAdminByCcns(ccns) {
      this.adminByCcns = ccns
    },
    setAdminMode(adminMode) {
      this.adminMode = adminMode
    },
    showConfirmation() {
      this.updateSelected()
      this.accessibilityAnnounce('Course site details form loaded.')
      this.currentWorkflowStep = 'confirmation'
    },
    showSelecting() {
      this.currentWorkflowStep = 'selecting'
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
}
</style>
