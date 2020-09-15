<template>
  <b-container fluid>
    <ToolboxHeader />
    <b-row class="p-3">
      <b-col>
        <h1 class="text-secondary">{{ $currentUser.firstName }}'s Toolbox</h1>
      </b-col>
    </b-row>
    <b-row class="pl-3 pr-3" sm="6">
      <b-col v-if="canActAs" sm="6">
        <ActAs />
      </b-col>
      <b-col :sm="canActAs ? 6 : 12">
        OEC
      </b-col>
    </b-row>
    <Footer />
  </b-container>
</template>

<script>
import ActAs from '@/components/toolbox/ActAs'
import Footer from '@/components/Footer'
import ToolboxHeader from '@/components/toolbox/ToolboxHeader'

export default {
  name: 'Toolbox',
  components: {ToolboxHeader, ActAs, Footer},
  data: () => ({
    canActAs: undefined
  }),
  created() {
    this.canActAs = this.$currentUser.isSuperuser || this.$currentUser.isViewer
  }
}
</script>

<style scoped>
h1 {
  font-size: 24px;
}
</style>
