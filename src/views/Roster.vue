<template>
  <div v-if="roster">
    <b-container>
      <b-row>
        <b-col sm="6">
          <div class="d-flex flex-wrap">
            <div>
              <b-input placeholder="Search People"></b-input>
            </div>
            <div v-if="roster.sections">
              <b-form-select
                id="section-select"
                v-model="section"
                :options="roster.sections"
                text-field="name"
                value-field="ccn"
                @change="onSectionChange"
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
      <b-row>
        <b-col sm="12">
          <ul class="d-flex align-content-start flex-wrap">
            <li v-for="student in roster.students" :key="student.student_id">
              {{ student.student_id }}
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
                <div class="cc-page-roster-student-name" data-ng-bind="student.first_name"></div>
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
                <span data-ng-bind="student.student_id"></span>
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
    <div>
      {{ roster }}
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
  data: () => ({
    context: 'canvas',
    courseId: undefined,
    roster: undefined,
    section: null
  }),
  mounted() {
    this.courseId = this.toInt(this.$_.get(this.$route, 'params.id'))
    getRoster(this.courseId).then(data => {
      this.roster = data
      this.$ready('Roster')
    })
  },
  methods: {
    onSectionChange() {

    }
  }
}
</script>
