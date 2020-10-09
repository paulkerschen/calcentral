<template>
  <div>
    <h2 class="cc-visuallyhidden">Course Site Creation</h2>
    <div aria-live="polite">
      <div v-show="!jobStatus" class="bc-page-create-course-site-pending-request">
        <fa icon="spinner" spin></fa>
        Sending request...
      </div>
      <div v-if="jobStatus === 'New'" class="bc-page-create-course-site-pending-request">
        <fa icon="spinner" spin></fa>
        Course provisioning request sent. Awaiting processing....
      </div>
      <div v-if="jobStatus">
        <div>
          <ProgressBar :percent-complete-rounded="Math.round(percentComplete * 100)" />
        </div>
        <div v-if="jobStatus === 'Error'">
          <BackgroundJobError :error-config="errorConfig" :errors="errors" />
          <div class="bc-page-create-course-site-step-options">
            <div class="medium-12 columns">
              <div class="bc-form-actions">
                <button
                  id="start-over-button"
                  class="bc-canvas-button bc-canvas-button-primary"
                  type="button"
                  aria-controls="bc-page-create-course-site-selecting-step"
                  aria-label="Start over course site creation process"
                  @click="fetchFeed"
                >
                  Start Over
                </button>
                <button
                  id="go-back-button"
                  class="cc-button cc-page-button-grey"
                  type="button"
                  aria-controls="bc-page-create-course-site-confirmation-step"
                  aria-label="Go Back to Site Details Confirmation"
                  @click="showConfirmation"
                >
                  Back
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div v-if="jobStatus === 'Completed'" :aria-expanded="jobStatus === 'Completed'">
      <b-spinner size="sm"></b-spinner>
      <div class="cc-visuallyhidden" role="alert">
        Redirecting to new course site.
      </div>
    </div>
  </div>
</template>

<script>
import BackgroundJobError from '@/components/bcourses/shared/BackgroundJobError'
import ProgressBar from '@/components/bcourses/shared/ProgressBar'

export default {
  name: 'MonitoringJob',
  components: {
    BackgroundJobError,
    ProgressBar
  },
  props: {
    fetchFeed: {
      required: true,
      type: Function
    },
    jobStatus: {
      required: true,
      type: String
    },
    percentComplete: {
      required: true,
      type: Number
    },
    showConfirmation: {
      required: true,
      type: Function
    }
  }
}
</script>

<style scoped lang="scss">
.bc-page-create-course-site-pending-request {
  margin: 15px auto;
}

.bc-page-create-course-site-step-options {
  padding: 20px 0;
}
</style>
