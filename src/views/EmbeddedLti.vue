<template>
  <div ref="main" class="cc-container-main" role="main">
    <router-view />
  </div>
</template>

<script>
import Iframe from '@/mixins/Iframe'

export default {
  name: 'Embedded',
  mixins: [Iframe],
  methods: {
    /**
     * Update the iframe height on a regular basis to avoid embedded scrollbars on
     * bCourses LTI tools. The message is formatted to be received by a listener
     * in Canvas's public/javascripts/tool_inline.js file; unless it exceeds the
     * Canvas 5000px limit, in which case our own listener handles it.
     */
    iframeUpdateHeight() {
      const mainElement = this.$refs.main
      if (mainElement) {
        const frameHeight = mainElement.scrollHeight
        const messageSubject = frameHeight > 5000 ? 'changeParent' : 'lti.frameResize'
        const message = {
          subject: messageSubject,
          height: frameHeight
        }
        this.iframePostMessage(JSON.stringify(message))
      }
    }
  },
  mounted() {
    if (this.isInIframe) {
      setInterval(this.iframeUpdateHeight, 250)
    }
  }
}
</script>
