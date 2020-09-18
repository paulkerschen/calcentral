<template>
  <div>
    <ToolboxHeader />
    <b-row class="cc-off-canvas-container" no-gutters>
      <b-col class="cc-offcanvas-right">
        <div id="cc-main-content" class="cc-container-main cc-container-standalone" role="main">
          <router-view />
        </div>
      </b-col>
    </b-row>
    <Footer :include-build-summary="true" />
  </div>
</template>

<script>
import Footer from '@/components/Footer'
import ToolboxHeader from '@/components/toolbox/ToolboxHeader'

export default {
  name: 'StandaloneLti',
  components: {Footer, ToolboxHeader}
}
</script>
