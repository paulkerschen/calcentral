<template>
  <b-container fluid>
    <ToolboxHeader />
    <b-row>
      <b-col class="text-center">
        <router-view />
      </b-col>
    </b-row>
    <Footer />
  </b-container>
</template>

<script>
import Footer from '@/components/Footer'
import ToolboxHeader from '@/components/toolbox/ToolboxHeader'

export default {
  name: 'StandaloneLti',
  components: {Footer, ToolboxHeader}
}
</script>
