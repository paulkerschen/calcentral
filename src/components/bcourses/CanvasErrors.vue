<template>
  <div class="bc-alert-container">
    <i class="fa fa-warning bc-alert-error-icon"></i>
    <div
      id="canvas-error-container"
      aria-live="polite"
      class="bc-notice-text-container"
      role="alert"
    >
      <h1 class="bc-notice-text-header">{{ decamelize(errorType) }}</h1>
      <p v-if="message" class="pt-2">{{ message }}</p>
      <p v-if="!message && errorType === 'unauthorized'" class="pt-2">
        You are unauthorized to use this feature. Please contact bCourses support for further assistance.
      </p>
      <p>Please contact <OutboundLink href="http://ets.berkeley.edu/discover-services/bcourses">bCourses support</OutboundLink> for further assistance.</p>
    </div>
  </div>
</template>

<script>
import OutboundLink from '@/components/util/OutboundLink'
import Utils from '@/mixins/Utils'

export default {
  name: 'CanvasErrors',
  mixins: [Utils],
  components: {OutboundLink},
  props: {
    errorType: {
      default: 'badRequest',
      required: false,
      type: String
    },
    message: {
      default: undefined,
      required: false,
      type: String
    }
  }
}
</script>
