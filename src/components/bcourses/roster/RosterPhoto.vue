<template>
  <div>
    <img
      :id="`student-photo-${student.student_id}`"
      :alt="`Photo of ${student.first_name} ${student.last_name}`"
      :aria-label="`Photo of ${student.first_name} ${student.last_name}`"
      class="photo"
      :src="photoUrl"
      @error="imageError"
    />
  </div>
</template>

<script>
export default {
  name: 'RosterPhoto',
  props: {
    student: {
      required: true,
      type: Object
    }
  },
  data: () => ({
    photoUrl: undefined
  }),
  created() {
    if (this.student.photo) {
      this.photoUrl = this.$config.apiBaseUrl ? `${this.$config.apiBaseUrl}${this.student.photo}` : this.student.photo
    } else {
      this.imageError()
    }
  },
  methods: {
    imageError() {
      this.photoUrl = require('@/assets/images/svg/photo_unavailable_official_72x96.svg')
    }
  }
}
</script>

<style scoped>
.photo {
  background-image: url('~@/assets/images/svg/photo_unavailable_official_72x96.svg');
  background-size: cover;
  height: 96px;
  margin: 0 auto;
  width: auto;
}
@media print {
  .photo {
    height: 147px;
  }
}
</style>
