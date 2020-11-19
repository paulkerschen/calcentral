<template>
  <b-container class="pl-0 pr-0" fluid>
    <ToolboxHeader />
    <b-row class="mb-2 mt-4" no-gutters>
      <b-col class="pl-3">
        <h1 class="cc-text-xl text-secondary">{{ $currentUser.firstName }}'s Toolbox</h1>
      </b-col>
    </b-row>
    <b-row v-if="canViewAs || this.$currentUser.canAdministerOec">
      <b-col v-if="canViewAs" sm="6">
        <ActAs />
      </b-col>
      <b-col v-if="this.$currentUser.canAdministerOec" sm="6">
        <Oec />
      </b-col>
    </b-row>
    <b-row v-if="!canViewAs && !this.$currentUser.canAdministerOec">
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
    canViewAs: undefined
  }),
  created() {
    this.canViewAs = this.$currentUser.isDirectlyAuthenticated && this.$currentUser.canViewAs
    this.$ready('Toolbox')
  }
}
</script>
