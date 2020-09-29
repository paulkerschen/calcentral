<template>
  <div class="bc-template-progress-bar">
    <div class="bc-template-progress-bar-container" c-if="percentCompleteRounded">
      <div
        class="bc-template-progress-bar-display"
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax="100"
        :aria-valuenow="percentCompleteRounded"
      ></div>
      <div class="bc-template-progress-bar-status">{{ percentCompleteRounded }}% Complete</div>
      <div class="bc-template-progress-bar-value" :style="{ width: percentCompleteRounded + '%' }"></div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ProgressBar',
  props: {
    percentCompleteRounded: {
      type: Number,
      default: 0
    }
  }
}
</script>
