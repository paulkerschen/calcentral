<template>
  <div>
    <div class="d-flex justify-content-between">
      <div>
        Berkeley &copy; {{ new Date().getFullYear() }} UC Regents
      </div>
      <div>
        <div class="d-flex">
          <div>Return to bCourses</div>
          <div>|</div>
          <div>Usage Policy</div>
          <div>|</div>
          <div>About</div>
        </div>
      </div>
    </div>
    <div v-if="$currentUser.isBasicAuthEnabled" class="p-3">
      <h4 id="basic-auth-header">Basic Auth</h4>
      <b-form @submit="devAuth">
      </b-form>
      <div class="p-1">
        <b-form-input
          id="basic-auth-uid"
          v-model="uid"
          placeholder="UID"
          required></b-form-input>
      </div>
      <div class="p-1">
        <b-form-input
          id="basic-auth-password"
          v-model="password"
          autocomplete="off"
          type="password"
          placeholder="Password"
          required></b-form-input>
      </div>
      <div class="p-1">
        <b-button id="basic-auth-submit-button" variant="primary" @click="devAuth">Login</b-button>
      </div>
      <b-popover :show.sync="showError" target="basic-auth-header" title="Error">
        <span class="text-danger">{{ error }}</span>
      </b-popover>
    </div>
  </div>
</template>

<script>
import Context from '@/mixins/Context';
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
        const redirect = this.$_.get(this.$router, 'currentRoute.query.redirect')
        devAuthLogIn(uid, password, redirect || `/toolbox`).then(
          data => {
            if (data.isAuthenticated) {
              this.$router.push({ path: redirect || '/toolbox' }, this.$_.noop)
              this.alertScreenReader('Welcome to Junction')
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
        this.putFocusNextTick('basic-auth-uid')
      } else {
        this.reportError('Both UID and password are required')
        this.putFocusNextTick('basic-auth-password')
      }
    },
    reportError(message) {
      this.error = message
    }
  }
}
</script>
