<template>
  <ul v-if="students.length" class="align-content-start d-flex flex-wrap">
    <li v-for="student in students" :key="student.student_id" class="pl-5 pr-5 text-center">
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
          <OutboundLink :id="`student-email-${student.student_id}-first-name`" :href="`mailto:${student.email}`">
            {{ student.first_name }}
          </OutboundLink>
        </div>
        <div class="cc-page-roster-student-name font-weight-bolder">
          <OutboundLink :id="`student-email-${student.student_id}`" :href="`mailto:${student.email}`">
            {{ student.last_name }}
          </OutboundLink>
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
</template>

<script>
import OutboundLink from '@/components/util/OutboundLink'
import RosterPhoto from '@/components/bcourses/roster/RosterPhoto'

export default {
  name: 'RosterPhotos',
  components: {OutboundLink, RosterPhoto},
  props: {
    courseId: {
      required: true,
      type: Number
    },
    students: {
      required: true,
      type: Array
    }
  },
  data: () => ({
    context: 'canvas'
  })
}
</script>

<style scoped>

</style>
