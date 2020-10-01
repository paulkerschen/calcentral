<template>
  <b-row class="cc-print-hide pb-5 w-100" no-gutters>
    <b-col>
      <b-container class="tangerine-border m-0 w-100" fluid>
        <b-row
          v-if="$currentUser.isDirectlyAuthenticated || !$currentUser.isLoggedIn"
          class="mt-3 text-secondary"
          no-gutters
        >
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
                <OutboundLink href="https://bcourses.berkeley.edu">Return to bCourses</OutboundLink>
              </div>
              <div class="pl-1 pr-1">|</div>
              <div>
                <OutboundLink href="https://security.berkeley.edu/policy">Usage Policy</OutboundLink>
              </div>
              <div class="pl-1 pr-1">|</div>
              <div>
                <OutboundLink href="https://www.ets.berkeley.edu/services-facilities/bcourses">About<span class="sr-only"> bCourses</span></OutboundLink>
              </div>
            </div>
          </b-col>
        </b-row>
        <b-row v-if="$currentUser.isLoggedIn && !$currentUser.isDirectlyAuthenticated" class="border-top pl-3 pt-3 text-secondary w-100" no-gutters>
          <b-col class="pt-1" sm="8">
            <div aria-live="polite" role="alert">
              You are viewing as {{ $currentUser.fullName }} ({{ $currentUser.uid }}),
              <span v-if="$currentUser.firstLoginAt">first logged in on {{ $currentUser.firstLoginAt | moment('M/D/YY') }}</span>
              <span v-if="!$currentUser.firstLoginAt">who has never logged in to CalCentral</span>
            </div>
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
              <span class="font-weight-bolder">Screen-reader alert:</span> {{ screenReaderAlert || '&mdash;' }}
            </div>
          </b-col>
        </b-row>
      </b-container>
    </b-col>
  </b-row>
</template>

<script>
import BuildSummary from '@/components/util/BuildSummary'
import Context from '@/mixins/Context'
import DevAuth from '@/components/util/DevAuth'
import OutboundLink from '@/components/util/OutboundLink'
import {stopActAs} from '@/api/act'

export default {
  name: 'Footer',
  mixins: [Context],
  components: {BuildSummary, DevAuth, OutboundLink},
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
.tangerine-border {
  border-top: 2px solid $cc-color-dark-tangerine;
}
</style>
