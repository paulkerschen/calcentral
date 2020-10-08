<template>
  <b-container fluid>
    <ToolboxHeader />
    <b-row class="ml-4 mt-4 pt-4">
      <b-col>
        <div class="d-flex">
          <div class="pr-3 pt-2">
            <fa class="text-warning" icon="exclamation-triangle" size="2x" />
          </div>
          <div>
            <h1 class="cc-text-xl text-secondary">Page Not Found</h1>
          </div>
        </div>
      </b-col>
    </b-row>
    <b-row class="cc-text-big ml-4 mt-4 pb-5">
      <b-col>
        <span id="error-message" aria-live="polite" role="alert">
          <span v-if="$route.redirectedFrom">
            The requested URL {{ this.$route.redirectedFrom }} was not found.
          </span>
          <span v-if="!$route.redirectedFrom">
            Page not found.
          </span>
          If you need assistance then please <a id="contact-us" href="https://dls.berkeley.edu/services/bcourses-0" target="_blank">contact us</a>.
        </span>
      </b-col>
    </b-row>
    <Footer :include-build-summary="true" />
  </b-container>
</template>

<script>
import Footer from '@/components/Footer'
import ToolboxHeader from '@/components/toolbox/ToolboxHeader'

export default {
  name: 'NotFound',
  components: {Footer, ToolboxHeader},
  mounted() {
    this.$ready('404')
  }
}
</script>
