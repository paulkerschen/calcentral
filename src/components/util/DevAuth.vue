<template>
  <div class="d-inline-flex">
    <b-form class="border-0" @submit="devAuth">
      <div class="p-1">
        <b-form-input
          id="basic-auth-uid"
          v-model="uid"
          aria-invalid="!!error"
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
        <b-form-invalid-feedback :state="!this.error">
          {{ error }}
        </b-form-invalid-feedback>
        <div class="pt-2">
          <b-button
            id="basic-auth-submit-button"
            class="cc-button-blue"
            size="sm"
            variant="outline-secondary"
            @click="devAuth"
          >
            Login
          </b-button>
        </div>
      </div>
    </b-form>
  </div>
</template>

<script>
import axios from 'axios'
import Context from '@/mixins/Context'
import Utils from '@/mixins/Utils'
import Vue from 'vue'
import {devAuthLogIn} from '@/api/auth'

export default {
  name: 'DevAuth',
  mixins: [Context, Utils],
  data: () => ({
    error: undefined,
    uid: undefined,
    password: undefined,
    showError: false
  }),
  methods: {
    devAuth() {
      let uid = this.$_.trim(this.uid)
      let password = this.$_.trim(this.password)
      if (uid && password) {
        devAuthLogIn(uid, password).then(
          data => {
            if (data.isLoggedIn) {
              axios.get(`${this.$config.apiBaseUrl}/api/my/status`).then(response => {
                axios.defaults.headers.post['X-CSRF-Token'] = response.data.csrfToken
                axios.defaults.headers.put['X-CSRF-Token'] = response.data.csrfToken
                axios.defaults.headers.delete['X-CSRF-Token'] = response.data.csrfToken

                Vue.prototype.$currentUser = response.data
                this.alertScreenReader('You are logged in.')
                this.$router.push({ path: '/' })
              })
            } else {
              const message = this.$_.get(data, 'response.data.error') || this.$_.get(data, 'response.data.message') || this.$_.get(data, 'message') || 'Authentication failed'
              this.reportError(message)
            }
          },
          error => {
            this.reportError(error)
          }
        )
      } else if (uid) {
        this.reportError('Password required')
      } else {
        this.reportError('Both UID and password are required', 'basic-auth-password')
      }
    },
    reportError(message, putFocus='basic-auth-uid') {
      this.error = message
      this.alertScreenReader(message)
      this.$putFocusNextTick(putFocus)
    }
  }
}
</script>
