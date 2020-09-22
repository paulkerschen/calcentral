<template>
  <div class="cc-page-roster">
    <b-container v-if="roster" fluid>
      <b-row align-v="start" class="cc-page-roster cc-roster-search" no-gutters>
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
              <template v-slot:first>
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
              >
                <fa icon="print" size="1x" variant="primary" /> Print<span class="sr-only"> roster of students</span>
              </b-button>
            </div>
          </div>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col class="pt-5" sm="12">
          <ul v-if="studentsFiltered.length" class="align-content-start d-flex flex-wrap">
            <li v-for="student in studentsFiltered" :key="student.student_id" class="pl-5 pr-5 text-center">
              <div v-if="student.profile_url">
                <a :id="`student-profile-url-${student.student_id}`" :href="student.profile_url" target="_top">
                  <RosterPhoto :student="student" />
                </a>
              </div>
              <div v-if="!student.profile_url">
                <a :id="`student-profile-url-${student.student_id}`" :href="`/${context}/${courseId}/profile/${student.login_id}`" target="_top">
                  <RosterPhoto :student="student" />
                </a>
              </div>
              <div v-if="!student.email">
                <div class="cc-page-roster-student-name">{{ student.first_name }}</div>
                <div class="cc-page-roster-student-name font-weight-bolder">
                  {{ student.last_name }}
                </div>
              </div>
              <div v-if="student.email">
                <div class="cc-page-roster-student-name">
                  <a :href="`mailto:${student.email}`">
                    {{ student.first_name }}
                  </a>
                </div>
                <div class="cc-page-roster-student-name font-weight-bolder">
                  <a :id="`student-email-${student.student_id}`" :href="`mailto:${student.email}`">{{ student.last_name }}</a>
                </div>
              </div>
              <div :id="`student-id-${student.student_id}`" class="cc-print-hide">
                <span class="sr-only">Student ID: </span>
                {{ student.student_id }}
              </div>
              <div v-if="student.terms_in_attendance" class="cc-page-roster-student-terms cc-print-hide">
                Terms: {{ student.terms_in_attendance }}
              </div>
              <div v-if="student.majors" class="cc-page-roster-student-majors cc-print-hide">
                {{ $_.truncate(student.majors.join(', '), {length: 50}) }}
              </div>
            </li>
          </ul>
        </b-col>
      </b-row>
    </b-container>
    <div v-if="!roster">
      <b-alert aria-live="polite" role="alert" show>Downloading rosters. This may take a minute for larger classes.</b-alert>
      <b-card>
        <b-skeleton animation="fade" width="85%"></b-skeleton>
        <b-skeleton animation="fade" width="55%"></b-skeleton>
        <b-skeleton animation="fade" width="70%"></b-skeleton>
      </b-card>
    </div>
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import RosterPhoto from '@/components/bcourses/roster/RosterPhoto'
import Util from '@/mixins/Utils'
import {getRoster, getRosterCsv} from '@/api/canvas'

export default {
  name: 'RosterPhotos',
  mixins: [Context, Util],
  components: {RosterPhoto},
  watch: {
    search() {
      this.updateStudentsFiltered()
    }
  },
  data: () => ({
    context: 'canvas',
    courseId: undefined,
    search: undefined,
    roster: undefined,
    section: null,
    studentsFiltered: undefined
  }),
  mounted() {
    this.courseId = this.toInt(this.$_.get(this.$route, 'params.id'))
    getRoster(this.courseId).then(data => {
      this.roster = data
      const students = []
      this.$_.each(this.roster.students, student => {
        student.idx = this.idx(`${student.first_name} ${student.last_name}`)
        students.push(student)
      })
      this.studentsFiltered = this.sort(students)
      this.$ready('Roster')
    })
  },
  methods: {
    downloadCsv() {
      getRosterCsv(this.courseId).then(() => {
        this.alertScreenReader(`${this.roster.canvas_course.name} CSV downloaded`)
      })
    },
    idx(value) {
      return value && this.$_.trim(value).replace(/[^\w\s]/gi, '').toLowerCase()
    },
    sort(students) {
      return  this.$_.sortBy(students, s => s.last_name)
    },
    updateStudentsFiltered() {
      const snippet = this.idx(this.search)
      const students = this.$_.filter(this.roster.students, student => {
        let idxMatch = !snippet || student.idx.includes(snippet)
        return idxMatch && (!this.section || this.$_.includes(student.section_ccns, this.section.toString()))
      })
      this.studentsFiltered = this.sort(students)
    }
  }
}
</script>

<style scope>
button {
  height: 38px;
  width: 76px;
}
</style>
