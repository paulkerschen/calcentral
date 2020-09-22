<template>
  <div class="cc-page-roster">
    <b-container v-if="roster">
      <b-row class="cc-page-roster cc-roster-search" no-gutters>
        <b-col sm="6">
          <div class="d-flex flex-wrap">
            <div class="pr-2">
              <b-input v-model="search" placeholder="Search People"></b-input>
            </div>
            <div v-if="roster.sections">
              <b-form-select
                id="section-select"
                v-model="section"
                :options="roster.sections"
                text-field="name"
                value-field="ccn"
                @change="updateStudentsFiltered"
              >
                <template v-slot:first>
                  <b-form-select-option :value="null">All sections</b-form-select-option>
                </template>
              </b-form-select>
            </div>
          </div>
        </b-col>
        <b-col sm="6">
          <div class="float-right">
            <div class="d-flex flex-wrap">
              <div>
                <b-button class="cc-text-light" size="lg" variant="cc-light"><fa class="text-dark" icon="file-download" /> Export</b-button>
              </div>
              <div>
                <b-button class="cc-button-blue" size="lg" variant="cc-blue"><fa icon="print" variant="primary" /> Print</b-button>
              </div>
            </div>
          </div>
        </b-col>
      </b-row>
      <b-row no-gutters>
        <b-col class="pt-5" sm="12">
          <ul v-if="studentsFiltered.length" class="d-flex align-content-start flex-wrap">
            <li v-for="student in studentsFiltered" :key="student.student_id" class="pl-5 pr-5 text-center">
              <div v-if="student.profile_url">
                <a :href="student.profile_url" target="_top">
                  <RosterPhoto :student="student" />
                </a>
              </div>
              <div v-if="!student.profile_url">
                <a :href="`/${context}/${courseId}/profile/${student.login_id}`" target="_top">
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
                  <a :href="`mailto:${student.email}`">{{ student.last_name }}</a>
                </div>
              </div>
              <div class="cc-print-hide">
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
      <b-alert show>Downloading rosters. This may take a minute for larger classes.</b-alert>
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
import {getRoster} from '@/api/canvas'

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
