<template>
  <b-row class="bg-header p-3 cc-masthead" no-gutters>
    <b-col sm="8">
      <div class="header-text pt-1">
        ETS bCourses Utilities
      </div>
    </b-col>
    <b-col sm="4">
      <b-button
        id="log-out"
        class="float-right p-0 text-white"
        variant="link"
        @click="exit"
      >
        Log out
      </b-button>
    </b-col>
  </b-row>
</template>

<script>
import {logOut} from '@/api/auth'

export default {
  name: 'ToolboxHeader',
  methods: {
    exit() {
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
