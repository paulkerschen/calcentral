<template>
  <b-row class="fixed pl-3 w-100">
    <b-row v-if="$currentUser.isDirectlyAuthenticated">
      <b-col sm="6">
        <div>
          Berkeley &copy; {{ new Date().getFullYear() }} UC Regents
        </div>
        <div class="pt-3">
          <div class="d-flex">
            <div class="pt-2">
              <h4>Build Summary</h4>
            </div>
            <div>
              <b-button
                id="toggle-show-build-summary"
                aria-controls="build-summary-collapse"
                variant="link"
                @click="showBuildSummary = !showBuildSummary"
              >
                <fa :icon="showBuildSummary ? 'caret-up' : 'caret-down'" />
              </b-button>
            </div>
          </div>
          <b-collapse id="build-summary-collapse" v-model="showBuildSummary" class="mt-2">
            <BuildSummary />
          </b-collapse>
        </div>
        <div v-if="$currentUser.isBasicAuthEnabled && !$currentUser.isLoggedIn" class="pt-2">
          <div class="d-flex">
            <div class="pt-2">
              <h4>DevAuth</h4>
            </div>
            <div>
              <b-button
                id="toggle-show-dev-auth"
                aria-controls="dev-auth-collapse"
                variant="link"
                @click="showDevAuth = !showDevAuth"
              >
                <fa :icon="showDevAuth ? 'caret-up' : 'caret-down'" />
              </b-button>
            </div>
          </div>
          <b-collapse id="dev-auth-collapse" v-model="showDevAuth">
            <DevAuth />
          </b-collapse>
        </div>
      </b-col>
      <b-col sm="6">
        <div class="d-flex flex-wrap float-right">
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
      </b-col>
    </b-row>
    <b-row v-if="!$currentUser.isDirectlyAuthenticated" class="border-top pl-3 pt-3 text-secondary w-100">
      <b-col class="pt-1" sm="10">
        You are viewing as {{ $currentUser.fullName }} ({{ $currentUser.uid }}),
        <span v-if="$currentUser.firstLoginAt">first logged in on {{ $currentUser.firstLoginAt | moment('M/D/YY') }}</span>
        <span v-if="!$currentUser.firstLoginAt">who has never logged in to CalCentral</span>
      </b-col>
      <b-col class="pb-3 pr-0" sm="2">
        <div class="float-right">
          <b-button
            id="stop-viewing-as"
            size="sm"
            variant="primary"
            @click="stopActAs"
          >
            Stop viewing as
          </b-button>
        </div>
      </b-col>
    </b-row>
  </b-row>
</template>

<script>
import BuildSummary from '@/components/util/BuildSummary'
import DevAuth from '@/components/util/DevAuth'
import {stopActAs} from '@/api/act'

export default {
  name: 'Footer',
  components: {DevAuth, BuildSummary},
  data: () => ({
    showBuildSummary: false,
    showDevAuth: false
  }),
  methods: {
    stopActAs() {
      stopActAs().then(() => window.location.href = '/')
    }
  }
}
</script>

<style scoped>
h4 {
  font-size: 18px;
}
.fixed {
  bottom: 0;
  left: 0;
  position: fixed;
  z-index: 9999;
  @media print {
    position: relative;
    p {
      border-top: 2px solid #000;
    }
  }
}
</style>
