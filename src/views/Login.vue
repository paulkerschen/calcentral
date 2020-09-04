<template>
  <div class="d-flex flex-column-reverse p-3 w-50">
    <div>
      <h1>ETS Support Utilities</h1>
    </div>
    <div class="ml-1 mr-1 mt-2 pb-5">
      <img alt="bCourses logo" class="w-100" src="@/assets/images/bcourses_righthand.png">
    </div>
    <div>
      <b-button size="lg" @click="toCasLogin">Sign In</b-button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Login',
  methods: {
    toCasLogin() {
      window.location.href = `${this.$config.apiBaseUrl}/auth/cas`
    }
  }
}
</script>
