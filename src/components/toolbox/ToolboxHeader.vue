<template>
  <b-row v-if="!isInIframe" class="bg-header" no-gutters>
    <b-col sm="8">
      <div class="header-text mt-1 pl-3 pt-2">
        ETS bCourses Utilities
      </div>
    </b-col>
    <b-col cols="auto" sm="4">
      <div class="mt-1 pr-3">
        <b-button
          id="log-out"
          class="float-right text-white"
          variant="link"
          @click="exit"
        >
          Log out
        </b-button>
      </div>
    </b-col>
  </b-row>
</template>

<script>
import Context from '@/mixins/Context'
import Iframe from '@/mixins/Iframe'
import {logOut} from '@/api/auth'

export default {
  name: 'ToolboxHeader',
  mixins: [Context, Iframe],
  methods: {
    exit() {
      this.alertScreenReader('Logging out.')
      logOut().then(() => {
        window.location.href = '/'
      })
    }
  }
}
</script>

<style scoped>
.bg-header {
  background: #002e5b;
}
.header-text {
  color: #f1a91e;
  display: inline-block;
  font-weight: bold;
  line-height: 1.6;
}
</style>
