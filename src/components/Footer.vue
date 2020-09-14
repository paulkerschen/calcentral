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
    <div v-if="$currentUser.isBasicAuthEnabled && !$currentUser.isLoggedIn" class="d-inline-flex p-3">
      <b-form @submit="devAuth">
        <h4 id="basic-auth-header">Basic Auth</h4>
        <div class="p-1">
          <b-form-input
            id="basic-auth-uid"
            v-model="uid"
            placeholder="UID"
            size="sm"
            required
          ></b-form-input>
        </div>
        <div class="p-1">
          <b-form-input
            id="basic-auth-password"
            v-model="password"
            autocomplete="off"
            class="mb-2"
            placeholder="Password"
            required
            size="sm"
            type="password"
          ></b-form-input>
          <b-button
            id="basic-auth-submit-button"
            variant="primary"
            @click="devAuth"
          >
            Login
          </b-button>
        </div>
      </b-form>
    </div>
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Utils from '@/mixins/Utils'
import {devAuthLogIn} from '@/api/auth'

export default {
  name: 'Footer',
  data: () => ({
    error: undefined,
    uid: undefined,
    password: undefined,
    showError: false
  }),
  mixins: [Context, Utils],
  methods: {
    devAuth() {
      let uid = this.$_.trim(this.uid)
      let password = this.$_.trim(this.password)
      if (uid && password) {
        devAuthLogIn(uid, password).then(
          data => {
            if (data.isLoggedIn) {
              this.$router.push({ path: '/' })
            } else {
              const message = this.$_.get(data, 'response.data.message') || this.$_.get(data, 'message') || 'Authentication failed'
              this.reportError(message)
            }
          },
          error => {
            this.reportError(error)
          }
        )
      } else if (uid) {
        this.reportError('Password required')
        this.$putFocusNextTick('basic-auth-uid')
      } else {
        this.reportError('Both UID and password are required')
        this.$putFocusNextTick('basic-auth-password')
      }
    },
    reportError(message) {
      this.error = message
    }
  }
}
</script>
