<template>
  <div>
    <div class="d-flex justify-content-between">
      <div class="pl-3">
        Berkeley &copy; {{ new Date().getFullYear() }} UC Regents
      </div>
      <div>
        <div class="d-flex flex-wrap">
          <div>
            <a href="https://bcourses.berkeley.edu" target="_blank">Return to bCourses<span class="sr-only"> (link opens new browser tab)</span></a>
          </div>
          <div class="pl-1 pr-1">|</div>
          <div>
            <a href="https://security.berkeley.edu/policy" target="_blank">Usage Policy<span class="sr-only"> (link opens new browser tab)</span></a>
          </div>
          <div class="pl-1 pr-1">|</div>
          <div class="pr-3">
            <a href="https://www.ets.berkeley.edu/services-facilities/bcourses" target="_blank">About<span class="sr-only"> bCourses (link opens new browser tab)</span></a>
          </div>
        </div>
      </div>
    </div>
    <div class="pl-5 pt-3">
      <h4 id="junction-build-summary">Build Summary</h4>
      <BuildSummary />
    </div>
    <div v-if="$currentUser.isBasicAuthEnabled && !$currentUser.isLoggedIn" class="pl-5">
      <h4 id="basic-auth-header">DevAuth</h4>
      <DevAuth />
    </div>
  </div>
</template>

<script>
import BuildSummary from '@/components/util/BuildSummary'
import DevAuth from '@/components/util/DevAuth'

export default {
  name: 'Footer',
  components: {DevAuth, BuildSummary}
}
</script>

<style scoped>
h4 {
  font-size: 18px;
}
</style>
