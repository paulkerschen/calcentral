<template>
  <div class="bc-canvas-application bc-page-course-official-sections">
    <div v-if="!feedFetched" class="cc-spinner"></div>

    <div v-if="feedFetched && !displayError">
      <div v-if="currentWorkflowStep === 'staging'">
        <MaintenanceNotice course-action-verb="site is updated" />
      </div>

      <h1 class="bc-page-course-official-sections-header1 bc-accessibility-no-outline">Official Sections</h1>

      <div v-if="currentWorkflowStep === 'preview'">
        <div
          v-if="jobStatusMessage !== ''"
          id="bc-page-course-official-sections-job-status-notice"
          class="bc-alert"
          :class="{'bc-notice-error': (jobStatus !== 'sectionEditsCompleted'), 'bc-alert-success': (jobStatus === 'sectionEditsCompleted')}"
          role="alert"
        >
          {{ jobStatusMessage }}
          <div class="bc-alert-close-button-container">
            <button
              class="fa fa-times-circle bc-close-button"
              aria-controls="bc-page-course-official-sections-job-status-notice"
              @click="jobStatusMessage = ''"
            >
              <span class="sr-only">Hide Notice</span>
            </button>
          </div>
        </div>

        <h2 class="sr-only">Viewing Sections</h2>

        <div class="bc-page-course-official-sections-sections-area bc-page-course-official-sections-current-sections-white-border">
          <b-row no-gutters class="bc-page-course-official-sections-current-sections-header">
            <b-col md="4">
              <h3 class="bc-header bc-page-course-official-sections-existing-sections-header-label">
                Sections in this Course Site
              </h3>
            </b-col>
            <b-col md="8" class="cc-text-right">
              <button
                v-if="isTeacher"
                class="bc-canvas-button bc-canvas-button-primary bc-canvas-no-decoration bc-page-course-official-sections-button"
                @click="changeWorkflowStep('staging')"
              >
                Edit Sections
              </button>
            </b-col>
          </b-row>
          <b-row no-gutters class="bc-page-course-official-sections-courses-container">
            <b-col md="12" class="bc-page-course-official-sections-current-course">
              <CourseSectionsTable
                mode="preview"
                :sections="existingCourseSections"
                :row-class-logic="rowClassLogic"
                :row-display-logic="rowDisplayLogic"
              />
            </b-col>
          </b-row>
        </div>
      </div>

      <div v-if="currentWorkflowStep === 'staging'">
        <div class="bc-page-course-official-sections-sections-area bc-page-course-official-sections-current-sections-grey-border">
          <h2 class="sr-only">Managing Sections</h2>

          <b-row no-gutters class="row bc-page-course-official-sections-current-sections-header">
            <b-col md="4">
              <h3 class="bc-header bc-page-course-official-sections-existing-sections-header-label">
                Sections in this Course Site
              </h3>
            </b-col>
            <b-col md="8" class="cc-text-right">
              <button
                class="bc-canvas-button bc-canvas-no-decoration"
                type="button"
                aria-label="Cancel section modifications for this course site"
                @click="cancel"
              >
                Cancel
              </button>
              <button
                class="bc-canvas-button bc-canvas-button-primary bc-canvas-no-decoration"
                :disabled="totalStagedCount === 0"
                type="button"
                aria-label="Apply pending modifications to this course site"
                @click="saveChanges"
              >
                Save Changes
              </button>
            </b-col>
          </b-row>

          <b-row no-gutters class="bc-page-course-official-sections-courses-container">
            <b-col md="12" class="bc-page-course-official-sections-current-course">
              <CourseSectionsTable
                mode="currentStaging"
                :sections="allSections"
                :unstage-action="unstage"
                :stage-delete-action="stageDelete"
                :stage-update-action="stageUpdate"
                :row-class-logic="rowClassLogic"
                :row-display-logic="rowDisplayLogic"
              ></CourseSectionsTable>
            </b-col>
          </b-row>

          <b-row v-if="currentStagedCount() > 12" class="row">
            <b-col md="12" class="cc-text-right">
              <button
                class="bc-canvas-button bc-canvas-no-decoration"
                aria-label="Cancel section modifications for this course site"
                @click="changeWorkflowStep('preview')"
              >
                Cancel
              </button>
              <button
                :disabled="totalStagedCount === 0"
                class="bc-canvas-button bc-canvas-button-primary bc-canvas-no-decoration"
                aria-label="Apply pending modifications to this course site"
                @click="saveChanges"
              >
                Save Changes
              </button>
            </b-col>
          </b-row>
        </div>

        <div class="bc-page-course-official-sections-sections-area">
          <b-row no-gutters>
            <b-col md="12">
              <h3 class="bc-header bc-page-course-official-sections-available-sections-header-label">
                All sections available to add to this Course Site
              </h3>
            </b-col>
          </b-row>

          <div v-if="courseSemesterClasses.length > 0" class="bc-page-course-official-sections-courses-container">
            <div v-for="course in courseSemesterClasses" :key="course.course_code" class="bc-sections-course-container-bottom-margin">
              <div class="bc-sections-course-container">
                <button
                  type="button"
                  class="bc-button-link bc-page-course-official-sections-form-course-button"
                  :aria-controls="course.course_id"
                  @click="toggleCollapse(course)"
                >
                  <fa
                    class="cc-left bc-sections-triangle-icon mr-2"
                    :icon="course.collapsed ? 'caret-right' : 'caret-down'"
                  ></fa>
                  <h3 class="bc-sections-course-title">
                    {{ course.course_code }}
                    <span v-if="course.title"> : {{ course.title }}</span>
                  </h3>
                  <span v-if="course.sections && (course.sections.length === 1)"> (1 section)</span>
                  <span v-if="course.sections && (course.sections.length !== 1)"> ({{ course.sections.length }} sections)</span>
                </button>
                <div
                  v-if="!course.collapsed"
                  :id="course.course_id"
                  class="bc-page-course-official-sections-form-collapsible-container"
                  :aria-expanded="!course.collapsed"
                  role="region"
                >
                  <div v-if="course.sections.length > 1" class="bc-page-course-official-sections-form-select-all-option">
                    <button
                      v-if="!allSectionsAdded(course)"
                      class="bc-button-link bc-page-course-official-sections-form-select-all-option-button"
                      type="button"
                      aria-label="Add all sections for this course to the list of sections to be added"
                      @click="addAllSections(course)"
                    >
                      Add All
                    </button>
                    <span v-if="allSectionsAdded(course)">All Added</span>
                  </div>

                  <b-row no-gutters>
                    <b-col md="12">
                      <CourseSectionsTable
                        mode="availableStaging"
                        :sections="course.sections"
                        :unstage-action="unstage"
                        :stage-add-action="stageAdd"
                        :row-class-logic="rowClassLogic"
                        :row-display-logic="rowDisplayLogic"
                      ></CourseSectionsTable>
                    </b-col>
                  </b-row>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="currentWorkflowStep === 'processing'" aria-live="polite">
        <h2 class="bc-header bc-page-course-official-sections-existing-sections-header-label">
          Updating Official Sections in Course Site
        </h2>
        <div v-if="jobStatus === 'sendingRequest'" class="bc-page-course-official-sections-pending-request">
          <fa icon="spinner" class="cc-icon fa-spin mr-2"></fa>
          Sending request...
        </div>
        <div v-if="jobStatus === 'New'" class="bc-page-course-official-sections-pending-request">
          <fa icon="spinner" class="cc-icon fa-spin mr-2"></fa>
          Request sent. Awaiting processing....
        </div>
        <div v-if="jobStatus">
          <ProgressBar :percent-complete-rounded="percentCompleteRounded" />
        </div>
      </div>
    </div>

    <div v-if="displayError" class="bc-alert-container" role="alert">
      <i class="fa fa-warning bc-canvas-notice-icon"></i>
      <div class="bc-notice-text-container">
        <h1 class="bc-notice-text-header">Error</h1>
        <p>{{ displayError }}</p>
      </div>
    </div>
  </div>
</template>

<script>
import CanvasUtils from '@/mixins/CanvasUtils'
import Context from '@/mixins/Context'
import CourseSectionsTable from '@/components/bcourses/CourseSectionsTable'
import MaintenanceNotice from '@/components/bcourses/shared/MaintenanceNotice'
import ProgressBar from '@/components/bcourses/shared/ProgressBar'

import {courseProvisionJobStatus, getCourseSections, updateSiteSections} from '@/api/canvas'

export default {
  name: 'CourseManageOfficialSections',
  components: {
    CourseSectionsTable,
    MaintenanceNotice,
    ProgressBar
  },
  mixins: [CanvasUtils, Context],
  data: () => ({
    adminActingAs: null,
    adminSemesters: null,
    allSections: [],
    canvasCourse: {},
    courseSemesterClasses: [],
    currentWorkflowStep: null,
    displayError: null,
    existingCourseSections: [],
    feedFetched: false,
    isAdmin: false,
    isCourseCreator: false,
    isLoading: false,
    isTeacher: false,
    jobStatus: null,
    jobStatusMessage: '',
    percentCompleteRounded: 0,
    totalStagedCount: 0
  }),
  created() {
    this.getCanvasCourseId()
    this.fetchFeed()
  },
  methods: {
    addAllSections(course) {
      this.alertScreenReader('All sections selected for course: ' + course.title)
      course.sections.forEach(section => {
        if (section.isCourseSection) {
          section.stagedState = null
        } else {
          section.stagedState = 'add'
        }
      })
    },
    allSectionsAdded(course) {
      return !this.$_.find(course.sections, section => {
        return (!section.isCourseSection && section.stagedState !== 'add') || (section.isCourseSection && section.stagedState === 'delete')
      })
    },
    cancel() {
      this.changeWorkflowStep('preview')
      this.unstageAll()
    },
    changeWorkflowStep(step) {
      if (step === 'staging') {
        this.alertScreenReader('Edit section form loaded')
        this.jobStatus = null
        this.jobStatusMessage = ''
      } else if (step === 'preview') {
        this.alertScreenReader('Read only section list loaded')
      }
      this.currentWorkflowStep = step
    },
    currentStagedCount() {
      var stagedCount = 0
      this.allSections.forEach(section => {
        if ((section.isCourseSection && section.stagedState === null) || (!section.isCourseSection && section.stagedState === 'add')) {
          stagedCount++
        }
      })
      return stagedCount
    },
    expandParentClass(section) {
      section.parentClass.collapsed = false
    },
    fetchFeed() {
      this.isLoading = true
      getCourseSections(this.canvasCourseId).then(
        response => {
          this.percentCompleteRounded = null
          if (response.canvas_course) {
            this.canvasCourse = response.canvas_course
            this.isTeacher = this.canvasCourse.canEdit
            this.refreshFromFeed(response)
          } else {
            this.displayError = 'Failed to retrieve section data.'
          }
        },
        this.$errorHandler
      )
    },
    getStagedSections() {
      const sections = {
        addSections: [],
        deleteSections: [],
        updateSections: []
      }
      this.courseSemesterClasses.forEach(classItem => {
        classItem.sections.forEach(section => {
          if (section.stagedState === 'add') {
            sections.addSections.push(section.ccn)
          } else if (section.stagedState === 'delete') {
            sections.deleteSections.push(section.ccn)
          } else if (section.stagedState === 'update') {
            sections.updateSections.push(section.ccn)
          }
        })
      })
      return sections
    },
    loadCourseLists(teachingSemesters) {
      const courseSemester = this.$_.find(teachingSemesters, semester => {
        return (semester.termYear === this.canvasCourse.term.term_yr) && (semester.termCode === this.canvasCourse.term.term_cd)
      })
      if (courseSemester) {
        this.courseSemesterClasses = courseSemester.classes
        this.usersClassCount = this.courseSemesterClasses.length
        this.existingCourseSections = []
        this.allSections = []
        this.existingCcns = []
        this.courseSemesterClasses.forEach(classItem => {
          this.$set(classItem, 'collapsed', !classItem.containsCourseSections)
          classItem.sections.forEach(section => {
            section.parentClass = classItem
            this.allSections.push(section)
            section.stagedState = null
            this.canvasCourse.officialSections.forEach(officialSection => {
              if (officialSection.ccn === section.ccn && this.existingCcns.indexOf(section.ccn) === -1) {
                this.existingCcns.push(section.ccn)
                this.existingCourseSections.push(section)
                if (officialSection.name !== section.courseCode + ' ' + section.section_label) {
                  this.$set(section, 'nameDiscrepancy', true)
                }
              }
            })
          })
        })
      } else {
        this.usersClassCount = 0
      }
    },
    otherCourseSection(site) {
      return (site && (site.emitter === 'bCourses') && (site.id !== this.canvasCourse.canvasCourseId))
    },
    refreshFromFeed(feed) {
      if (feed.teachingSemesters) {
        this.loadCourseLists(feed.teachingSemesters)
      }
      this.isAdmin = feed.is_admin
      this.adminActingAs = feed.admin_acting_as
      this.adminSemesters = feed.admin_semesters
      this.isCourseCreator = this.usersClassCount > 0
      this.feedFetched = true
      this.currentWorkflowStep = 'preview'
    },
    rowClassLogic(listMode, section) {
      return {
        'bc-template-sections-table-row-added': (listMode === 'currentStaging' && section.stagedState === 'add'),
        'bc-template-sections-table-row-deleted': (listMode === 'availableStaging' && section.stagedState === 'delete'),
        'bc-template-sections-table-row-disabled': (
          listMode === 'availableStaging' &&
          (
            section.stagedState === 'add' ||
            (section.isCourseSection && section.stagedState !== 'delete')
          )
        )
      }
    },
    rowDisplayLogic(listMode, section) {
      return (listMode === 'preview') ||
        (listMode === 'availableStaging') ||
        (listMode === 'currentStaging' && section && section.isCourseSection && section.stagedState !== 'delete') ||
        (listMode === 'currentStaging' && section && !section.isCourseSection && section.stagedState === 'add')
    },
    saveChanges() {
      this.changeWorkflowStep('processing')
      this.jobStatus = 'sendingRequest'
      const update = this.getStagedSections()
      updateSiteSections(
        this.canvasCourse.canvasCourseId,
        update.addSections,
        update.deleteSections,
        update.updateSections
      ).then(
        response => {
          this.backgroundJobId = response.job_id
          this.trackSectionUpdateJob()
        }
      )
    },
    sectionString(section) {
      return section.courseCode + ' ' + section.section_label + ' (CCN: ' + section.ccn + ')'
    },
    stageAdd(section) {
      if (!section.isCourseSection) {
        this.$set(section, 'stagedState', 'add')
        this.alertScreenReader('Included in the list of sections to be added')
      } else {
        this.displayError = 'Unable to add ' + this.sectionString(section) + ', as it already exists within the course site.'
      }
      this.updateStagedCount()
    },
    stageDelete(section) {
      if (section.isCourseSection) {
        this.expandParentClass(section)
        this.$set(section, 'stagedState', 'delete')
        this.alertScreenReader('Included in the list of sections to be deleted')
      } else {
        this.displayError = 'Unable to delete CCN ' + this.sectionString(section) + ' which does not exist within the course site.'
      }
      this.updateStagedCount()
    },
    stageUpdate(section) {
      if (section.isCourseSection) {
        this.expandParentClass(section)
        this.$set(section, 'stagedState', 'update')
        this.alertScreenReader('Included in the list of sections to be updated')
      } else {
        this.displayError = 'Unable to update CCN ' + this.sectionString(section) + ' which does not exist within the course site.'
      }
      this.updateStagedCount()
    },
    trackSectionUpdateJob() {
      this.exportTimer = setInterval(() => {
        courseProvisionJobStatus(this.backgroundJobId).then(
          response => {
            this.jobStatus = response.jobStatus
            this.percentCompleteRounded = Math.round(response.percentComplete * 100)
            if (this.jobStatus !== 'New' && this.jobStatus !== 'Processing') {
              this.percentCompleteRounded = null
              clearInterval(this.exportTimer)
              if (this.jobStatus === 'Completed') {
                this.jobStatusMessage = 'The sections in this course site have been updated successfully.'
              } else {
                this.jobStatusMessage = 'An error has occurred with your request. Please try again or contact bCourses support.'
              }
              this.fetchFeed()
            }
          },
          this.$errorHandler
        )
      }, 2000)
    },
    toggleCollapse(course) {
      this.$set(course, 'collapsed', !course.collapsed)
    },
    unstage(section) {
      if (section.stagedState === 'add') {
        this.expandParentClass(section)
        this.alertScreenReader('Removed section from the list of sections to be added')
      } else {
        this.alertScreenReader('Included in the list of sections to be deleted')
      }
      section.stagedState = null
      this.updateStagedCount()
    },
    unstageAll() {
      this.courseSemesterClasses.forEach(classItem => {
        classItem.sections.forEach(section => {
          section.stagedState = null
        })
      })
      this.updateStagedCount()
    },
    updateStagedCount() {
      var stagedCount = 0
      this.allSections.forEach(section => {
        if (section.stagedState !== null) {
          stagedCount++
        }
      })
      this.totalStagedCount = stagedCount
    }
  }
}
</script>

<style scoped lang="scss">
.bc-page-course-official-sections {
  background-color: $bc-color-white;
  padding: 25px;
  .cc-button {
    padding: 10px;
  }

  .bc-page-course-official-sections-header1 {
    font-size: 24px;
    font-weight: 400;
    line-height: 30px;
    margin: 15px 0 16px;
  }

  .bc-page-course-official-sections-button {
    white-space: nowrap;
  }

  .bc-page-course-official-sections-courses-container {
    margin: 0;
  }

  .bc-page-course-official-sections-current-sections-grey-border {
    border: $bc-color-grey-area-border-dark solid 1px;
    .bc-page-course-official-sections-courses-container {
      margin-bottom: 15px;
    }

    .bc-page-course-official-sections-existing-sections-header-label {
      margin-top: 3px;
    }
  }

  .bc-page-course-official-sections-current-course {
    margin-left: 0;
    margin-top: 10px;
  }

  .bc-page-course-official-sections-current-sections-header {
    margin-bottom: 5px;
  }

  .bc-page-course-official-sections-current-sections-white-border {
    border: $cc-color-white solid 1px;
  }

  .bc-page-course-official-sections-sections-area.bc-page-course-official-sections-current-sections-grey-border {
    padding: 15px;
  }

  .bc-page-course-official-sections-sections-area + .bc-page-course-official-sections-sections-area {
    margin-top: 25px;
  }

  .bc-page-course-official-sections-existing-sections-header-label {
    font-size: 19px;
    margin-top: 10px;
  }

  .bc-page-course-official-sections-available-sections-header-label {
    font-size: 19px;
    margin-bottom: 15px;
  }

  .bc-page-course-official-sections-form-course-button {
    color: $bc-color-body-black;

    &:focus, &:hover {
      text-decoration: none;
    }
  }

  .bc-page-course-official-sections-form-collapsible-container {
    margin-top: 7px;
  }

  .bc-page-course-official-sections-form-select-all-option {
    font-size: 12px;
    margin: 6px 0 4px 2px;
  }

  .bc-page-course-official-sections-form-select-all-option-button {
    outline: none;
  }

  .bc-page-course-official-sections-pending-request {
    margin: 20px 0;
  }

  @media #{$small-only} {
    .bc-page-course-official-sections-small-only-align-left {
      text-align: left;
    }
  }
}
</style>
