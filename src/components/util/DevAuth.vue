<template>
  <div class="d-inline-flex">
    <b-form @submit="devAuth">
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
</template>

<script>
import Context from '@/mixins/Context'
import Utils from '@/mixins/Utils'
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
