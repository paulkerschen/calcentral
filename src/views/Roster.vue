<template>
  <div class="cc-page-roster">
    <b-container v-if="roster && !error" fluid>
      <b-row align-v="start" class="cc-page-roster cc-print-hide cc-roster-search" no-gutters>
        <b-col class="pb-2 pr-2" sm="3">
          <b-input
            id="roster-search"
            v-model="search"
            placeholder="Search People"
            size="lg"
          >
          </b-input>
        </b-col>
        <b-col class="pb-2" sm="3">
          <div v-if="roster.sections">
            <b-form-select
              id="section-select"
              v-model="section"
              :options="roster.sections"
              size="lg"
              text-field="name"
              value-field="ccn"
              @change="updateStudentsFiltered"
            >
              <template #first>
                <b-form-select-option :value="null">All sections</b-form-select-option>
              </template>
            </b-form-select>
          </div>
        </b-col>
        <b-col cols="auto" sm="6">
          <div class="d-flex flex-wrap float-right">
            <div class="pr-2">
              <b-button
                id="download-csv"
                class="cc-text-light"
                :disabled="!roster.students.length"
                size="md"
                variant="outline-secondary"
                @click="downloadCsv"
              >
                <fa class="text-secondary" icon="download" size="1x" /> Export<span class="sr-only"> CSV file</span>
              </b-button>
            </div>
            <div>
              <b-button
                id="print-roster"
                class="cc-button-blue"
                variant="outline-secondary"
                @click="printRoster"
              >
                <fa icon="print" size="1x" variant="primary" /> Print<span class="sr-only"> roster of students</span>
              </b-button>
            </div>
          </div>
        </b-col>
      </b-row>
      <b-row class=" cc-print-hide" :class="{'sr-only': !$config.isVueAppDebugMode}" no-gutters>
        <b-col sm="12">
          <div class="float-right pb-2">
            <b-form-radio-group
              id="toggle-view-mode"
              v-model="viewMode"
              :options="[
                { text: 'Photos', value: 'photos' },
                { text: 'List', value: 'list' }
              ]"
              name="radio-options"
              size="lg"
            ></b-form-radio-group>
          </div>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col class="pt-5" sm="12">
          <div v-if="viewMode === 'list'">
            <RosterList :course-id="canvasCourseId" :students="studentsFiltered" />
          </div>
          <div v-if="viewMode === 'photos'">
            <RosterPhotos :course-id="canvasCourseId" :students="studentsFiltered" />
          </div>
        </b-col>
      </b-row>
    </b-container>
    <div v-if="!roster & !error">
      <b-alert aria-live="polite" role="alert" show>Downloading rosters. This may take a minute for larger classes.</b-alert>
      <b-card>
        <b-skeleton animation="fade" width="85%"></b-skeleton>
        <b-skeleton animation="fade" width="55%"></b-skeleton>
        <b-skeleton animation="fade" width="70%"></b-skeleton>
      </b-card>
    </div>
    <div v-if="error" role="alert">
      <fa icon="exclamation-triangle" class="cc-icon-red"></fa> You must be a teacher in this bCourses course to view official student rosters.
    </div>
    <div v-if="!error && roster && !roster.sections" role="alert">
      <fa icon="exclamation-circle" class="cc-icon-gold"></fa> There are no currently maintained official sections in this course site.
    </div>
    <div v-if="!error && roster && roster.sections && !roster.students" role="alert">
      <fa icon="exclamation-circle" class="cc-icon-gold"></fa> Students have not yet signed up for this class.
    </div>
  </div>
</template>

<script>
import CanvasUtils from '@/mixins/CanvasUtils'
import Context from '@/mixins/Context'
import RosterList from '@/components/bcourses/roster/RosterList'
import RosterPhotos from '@/components/bcourses/roster/RosterPhotos'
import Utils from '@/mixins/Utils'
import {getRoster, getRosterCsv} from '@/api/canvas'

export default {
  name: 'Roster',
  mixins: [CanvasUtils, Context, Utils],
  components: {RosterList, RosterPhotos},
  watch: {
    search() {
      this.updateStudentsFiltered()
    },
    viewMode(value) {
      this.alertScreenReader(`View mode is '${value}'.`)
    }
  },
  data: () => ({
    canvasCourseId: undefined,
    error: null,
    search: undefined,
    roster: undefined,
    section: null,
    studentsFiltered: undefined,
    viewMode: 'photos'
  }),
  created() {
    this.getCanvasCourseId()
  },
  mounted() {
    getRoster(this.canvasCourseId).then(data => {
      this.roster = data
      const students = []
      this.$_.each(this.roster.students, student => {
        student.idx = this.idx(`${student.first_name} ${student.last_name}`)
        students.push(student)
      })
      this.studentsFiltered = this.sort(students)
      this.$ready('Roster')
    }, error => {
      this.error = error
      this.$ready('Roster')
    })
  },
  methods: {
    downloadCsv() {
      getRosterCsv(this.canvasCourseId).then(
        () => {
          this.alertScreenReader(`${this.roster.canvas_course.name} CSV downloaded`)
        },
        this.$errorHandler
      )
    },
    idx(value) {
      return value && this.$_.trim(value).replace(/[^\w\s]/gi, '').toLowerCase()
    },
    printRoster() {
      this.printPage(`${this.idx(this.roster.canvas_course.name).replace(/\s/g, '-')}_roster`)
    },
    sort(students) {
      return this.$_.sortBy(students, s => s.last_name)
    },
    updateStudentsFiltered() {
      const snippet = this.idx(this.search)
      const students = this.$_.filter(this.roster.students, student => {
        let idxMatch = !snippet || student.idx.includes(snippet)
        return idxMatch && (!this.section || this.$_.includes(student.section_ccns, this.section.toString()))
      })
      this.studentsFiltered = this.sort(students)
      let alert = this.section ? `Showing the ${this.studentsFiltered.length} students of section ${this.section}` : 'Showing all students'
      if (snippet) {
        alert += ` with '${snippet}' in name.`
      }
      this.alertScreenReader(alert)
    }
  }
}
</script>

<style scoped>
button {
  height: 38px;
  width: 76px;
}
</style>
