<template>
  <div>
    <div v-if="displayError === 'unauthorized'" class="bc-alert-container">
      <i class="fa fa-warning bc-alert-error-icon"></i>
      <div class="bc-notice-text-container">
        <h1 class="bc-notice-text-header">Access Denied</h1>
        <p v-if="accessDeniedError">{{ accessDeniedError }}</p>
        <p v-if="!accessDeniedError">You are unauthorized to use this feature. Please contact bCourses support for further assistance.</p>
      </div>
    </div>
    <div v-if="displayError === 'badRequest'" class="bc-alert-container">
      <i class="fa fa-warning bc-alert-error-icon"></i>
      <div class="bc-notice-text-container">
        <h1 class="bc-notice-text-header">Bad Request</h1>
        <p v-if="badRequestError">{{ badRequestError }}</p>
      </div>
    </div>
    <div v-if="displayError === 'failure'" class="bc-alert-container">
      <i class="fa fa-warning bc-alert-error-icon"></i>
      <div class="bc-notice-text-container">
        <h1 class="bc-notice-text-header">Unexpected Error</h1>
        <p>Please contact <a href="http://ets.berkeley.edu/discover-services/bcourses">bCourses support</a> for further assistance.</p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CanvasErrors',
  props: {
    displayError: {
      required: true,
      type: String
    }
  }
}
</script>
