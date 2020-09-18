<template>
  <div>
    <div class="text-center d-flex flex-column-reverse p-3 w-50">
      <div class="pb-5">
        <h1>ETS Support Utilities</h1>
      </div>
      <div>
        <img alt="bCourses logo" class="float-left img-fluid" src="@/assets/images/bcourses_righthand.png">
      </div>
      <div class="pt-5">
        <b-button
          id="sign-in-button"
          class="text-nowrap"
          size="md"
          variant="primary"
          @click="toCasLogin"
        >
          Sign In
        </b-button>
      </div>
    </div>
    <div>
      <Footer :show-build-summary="true" />
    </div>
  </div>
</template>

<script>
import Footer from '@/components/Footer'

export default {
  name: 'Login',
  components: {Footer},
  methods: {
    toCasLogin() {
      window.location.href = `${this.$config.apiBaseUrl}/auth/cas`
    }
  }
}
</script>

<style scoped>
h1 {
  color: #025a86;
  font-size: 23px;
  font-weight: bold;
  margin: 0 0 10px;
}
</style>
