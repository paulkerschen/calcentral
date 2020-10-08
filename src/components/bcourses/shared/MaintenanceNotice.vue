<template>
  <div class="bc-alert">
    <button
      id="maintenance-notice-button"
      class="bc-button-link bc-template-canvas-maintenance-notice-button"
      aria-controls="maintenance-details"
      :aria-expanded="!maintenanceCollapsed"
      aria-haspopup="true"
      @click="maintenanceCollapsed = !maintenanceCollapsed"
    >
      <fa
        :icon="maintenanceCollapsed ? 'caret-right' : 'caret-down'"
        class="cc-left bc-template-canvas-maintenance-notice-collapse-icon"
        aria-hidden="true"
      ></fa>
      <fa icon="exclamation-triangle" class="cc-icon-gold" aria-hidden="true"></fa>
      <span class="bc-template-canvas-maintenance-notice-text">
        From 8 - 9 AM, you may experience delays of up to 10 minutes before your {{ courseActionVerb }}.
      </span>
    </button>
    <div id="maintenance-details" aria-live="polite">
      <div v-if="!maintenanceCollapsed" class="bc-template-canvas-maintenance-notice-details">
        <p>
          bCourses performs scheduled maintenance every day between 8-9AM, during which time bCourses user
          and enrollment information is synchronized with other campus systems.
          This process may cause delays of up to 10 minutes before your request is completed.
          For more information, check the <OutboundLink href="http://ets.berkeley.edu/discover-services/bcourses">bCourses service page</OutboundLink>.
        </p>
      </div>
    </div>
  </div>
</template>

<script>
import OutboundLink from '@/components/util/OutboundLink'

export default {
  name: 'MaintenanceNotice',
  components: {OutboundLink},
  props: {
    courseActionVerb: {
      type: String,
      default: ''
    }
  },
  data: () => ({
    maintenanceCollapsed: true
  })
}
</script>
