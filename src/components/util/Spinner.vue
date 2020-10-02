<template>
  <div v-if="loading" id="spinner-when-loading" class="spinner">
    <b-spinner label="Spinner"></b-spinner>
  </div>
</template>

<script>
import Context from '@/mixins/Context.vue'

export default {
  mixins: [Context],
  watch: {
    loading(value) {
      this.alert(value, true)
    }
  },
  created() {
    this.alert(this.loading, false)
  },
  methods: {
    alert(isLoading, voiceIfLoaded)  {
      const prefix = this.alertPrefix || this.$_.get(this.$route, 'meta.title') || 'Page'
      if (isLoading) {
        this.alertScreenReader(`${prefix} is loading...`)
      } else if (voiceIfLoaded) {
        this.alertScreenReader(`${prefix} has loaded.`)
      }
    }
  }
}
</script>

<style scoped lang="scss">
.spinner {
  color: $cc-blue;
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  height: 2em;
  margin: auto;
  overflow: show;
  width: 2em;
  z-index: 999;
}
</style>
