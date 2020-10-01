<template>
  <b-container fluid>
    <ToolboxHeader />
    <b-row class="p-3">
      <b-col>
        <h1 class="cc-text-xl text-secondary">{{ $currentUser.firstName }}'s Toolbox</h1>
      </b-col>
    </b-row>
    <b-row class="pl-3 pr-3">
      <b-col v-if="canActAs || canOec" sm="6">
        <ActAs />
      </b-col>
      <b-col :sm="canActAs ? 6 : 12">
        <div v-if="$currentUser.isSuperuser">
          <Oec />
        </div>
      </b-col>
    </b-row>
    <b-row v-if="!canActAs && !canOec" class="pl-3 pr-3">
      <b-col sm="12">
        <div class="text-center">
          <img class="w-50" src="@/assets/images/conjunction-junction.jpg" alt="Image of train junction" />
        </div>
      </b-col>
    </b-row>
    <Footer class="pt-5" :include-build-summary="true" />
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
    canActAs: undefined,
    canOec: undefined
  }),
  created() {
    this.canActAs = this.$currentUser.isDirectlyAuthenticated && (this.$currentUser.isSuperuser || this.$currentUser.isViewer)
    this.canOec = this.$currentUser.isSuperuser
    this.$ready('Toolbox')
  }
}
</script>
