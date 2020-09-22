<template>
  <b-row class="bg-header cc-masthead" no-gutters>
    <b-col sm="8">
      <div class="header-text mt-1 pl-3 pt-2">
        ETS bCourses Utilities
      </div>
    </b-col>
    <b-col cols="auto" sm="4">
      <b-button
        id="log-out"
        class="float-right text-white"
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
