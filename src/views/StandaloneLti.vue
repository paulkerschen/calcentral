<template>
  <b-container fluid>
    <b-row>
      <b-col>
        <ToolboxHeader />
      </b-col>
    </b-row>
    <b-row>
      <b-col class="text-center">
        <router-view />
      </b-col>
    </b-row>
    <b-row>
      <b-col>
        <Footer />
      </b-col>
    </b-row>
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
