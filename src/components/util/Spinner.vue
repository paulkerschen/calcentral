<template>
  <div v-if="loading" id="spinner-when-loading" class="spinner">
    <b-spinner label="Spinner"></b-spinner>
  </div>
</template>

<script>
import Context from '@/mixins/Context.vue'

export default {
  name: 'Spinner',
  mixins: [Context]
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
