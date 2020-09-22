<template>
  <b-row class="bg-white cc-print-hide fixed pb-3 pl-3 pr-4 w-100 z-max" no-gutters>
    <b-row v-if="$currentUser.isDirectlyAuthenticated || !$currentUser.isLoggedIn" class="border-top pl-2 pt-3 text-secondary w-100" no-gutters>
      <b-col sm="6">
        <div>
          Berkeley &copy; {{ new Date().getFullYear() }} UC Regents
        </div>
        <div v-if="includeBuildSummary" class="pt-3">
          <div class="d-flex">
            <div>
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
          <b-collapse id="build-summary-collapse" v-model="showBuildSummary" class="ml-3">
            <BuildSummary />
          </b-collapse>
        </div>
        <div v-if="$currentUser.isBasicAuthEnabled && !$currentUser.isLoggedIn" class="pt-2">
          <div class="d-flex pb-2">
            <div>
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
          <div>
            <a href="https://www.ets.berkeley.edu/services-facilities/bcourses" target="_blank">About<span class="sr-only"> bCourses (link opens new browser tab)</span></a>
          </div>
        </div>
      </b-col>
    </b-row>
    <b-row v-if="$currentUser.isLoggedIn && !$currentUser.isDirectlyAuthenticated" class="border-top pl-3 pt-3 text-secondary w-100" no-gutters>
      <b-col class="pt-1" sm="8">
        You are viewing as {{ $currentUser.fullName }} ({{ $currentUser.uid }}),
        <span v-if="$currentUser.firstLoginAt">first logged in on {{ $currentUser.firstLoginAt | moment('M/D/YY') }}</span>
        <span v-if="!$currentUser.firstLoginAt">who has never logged in to CalCentral</span>
      </b-col>
      <b-col sm="4">
        <div class="float-right">
          <b-button
            id="stop-viewing-as"
            class="btn-stop-viewing-as cc-button-blue text-nowrap"
            size="sm"
            variant="outline-secondary"
            @click="stopActAs"
          >
            Stop viewing as
          </b-button>
        </div>
      </b-col>
    </b-row>
    <b-row v-if="$config.isVueAppDebugMode" class="pl-3 w-100">
      <b-col sm="12">
        <div class="text-secondary">
          <span class="font-weight-bolder">Screen-reader alert:</span> {{ screenReaderAlert }}
        </div>
      </b-col>
    </b-row>
  </b-row>
</template>

<script>
import BuildSummary from '@/components/util/BuildSummary'
import Context from '@/mixins/Context'
import DevAuth from '@/components/util/DevAuth'
import {stopActAs} from '@/api/act'

export default {
  name: 'Footer',
  mixins: [Context],
  components: {DevAuth, BuildSummary},
  props: {
    includeBuildSummary: {
      required: false,
      type: Boolean
    }
  },
  data: () => ({
    showBuildSummary: false,
    showDevAuth: true
  }),
  methods: {
    stopActAs() {
      stopActAs().then(() => window.location.href = '/')
    }
  }
}
</script>

<style lang="scss" scoped>
h4 {
  font-size: 18px;
}
.btn-stop-viewing-as {
  height: 25px;
  width: 110px;
}
.fixed {
  border-top: 2px solid $cc-color-dark-tangerine;
  bottom: 0;
  left: 0;
  position: fixed;
  @media print {
    position: relative;
    p {
      border-top: 2px solid #000;
    }
  }
}
.z-max {
  z-index: 9999;
}
</style>
