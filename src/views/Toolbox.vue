<template>
  <b-container fluid>
    <ToolboxHeader />
    <b-row class="p-3">
      <b-col>
        <h1 class="cc-text-xl text-secondary">{{ $currentUser.firstName }}'s Toolbox</h1>
      </b-col>
    </b-row>
    <b-row class="pl-3 pr-3" sm="6">
      <b-col v-if="canActAs" sm="6">
        <ActAs />
      </b-col>
      <b-col :sm="canActAs ? 6 : 12">
        <Oec />
      </b-col>
    </b-row>
    <Footer :show-build-summary="true" />
  </b-container>
</template>

<script>
import ActAs from '@/components/toolbox/ActAs'
import Footer from '@/components/Footer'
import Oec from '@/components/oec/Oec'
import ToolboxHeader from '@/components/toolbox/ToolboxHeader'

export default {
  name: 'Toolbox',
  components: {ActAs, Footer, Oec, ToolboxHeader},
  data: () => ({
    canActAs: undefined
  }),
  created() {
    this.canActAs = this.$currentUser.isDirectlyAuthenticated && (this.$currentUser.isSuperuser || this.$currentUser.isViewer)
    this.$ready('Toolbox')
  }
}
</script>
