<template>
  <div>
    <img
      v-if="student.photo && !student.loadError"
      :alt="`Photo of ${student.first_name} ${student.last_name}`"
      :aria-label="`Photo of ${student.first_name} ${student.last_name}`"
      data-cc-load-error-directive="student"
      :src="student.photo"
    />
    <div
      v-if="!student.photo || student.loadError"
      class="cc-image-responsive cc-page-roster-image-unavailable"
      :title="`Photo of ${student.first_name} ${student.last_name}`"
    >
      <span class="sr-only">{{ `No photo available for ${student.first_name} ${student.last_name}` }}</span>
    </div>
    {{ student }}
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
  }
}
</script>

<style scoped>
img {
  height: 96px;
  width: 72px;
}
</style>
