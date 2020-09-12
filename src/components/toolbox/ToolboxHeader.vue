<template>
  <div class="bg d-flex justify-content-between">
    <div class="header-text">
      bCourses Utilities
    </div>
    <div class="text-white">
      <b-button variant="link" @click="exit">Log out</b-button>
    </div>
  </div>
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
.header-text {
  color: #f1a91e;
  display: inline-block;
  font-weight: bold;
  line-height: 1.6;
}
.bg {
  background: #002e5b;
  height: 40px;
}
</style>
