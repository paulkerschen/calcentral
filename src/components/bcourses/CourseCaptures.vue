<template>
  <div class="bc-canvas-application">
    <div v-if="isLoading" class="cc-spinner"></div>

    <div v-if="!isLoading">
      <h1 class="cc-visuallyhidden">Course Captures</h1>

      <div v-if="!videos">
        There are no recordings available.
      </div>

      <div v-if="videos">
        <div v-if="media.length">
          <div v-for="(section, index) in media" :key="index" class="cc-table cc-webcast-table">
            <h3 v-if="media.length > 1" :class="{'cc-widget-section-header': index === 0}">
              {{ section.deptName }} {{ section.catalogId }} {{ section.instructionFormat }} {{ section.sectionNumber }}
            </h3>
            <div v-if="section.videos && section.videos.length" class="cc-widget-webcast-alert">
              <fa icon="exclamation-triangle" class="cc-icon-gold"></fa>
              <strong>Alert: </strong>
              Log in to YouTube with your bConnected account to watch the videos below. More information is at
              our <OutboundLink href="https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0011469">help page</OutboundLink>.
            </div>
            <div v-if="!section.videos.length">
              <span v-if="media.length > 1">Recordings will appear here after classes start.</span>
              <div v-if="media.length === 1">
                Recordings of
                {{ section.deptName }} {{ section.catalogId }} {{ section.instructionFormat }} {{ section.sectionNumber }}
                will appear here after classes start.
              </div>
            </div>
            <table v-if="section.videos.length">
              <thead>
                <tr>
                  <th width="60%" scope="col">
                    Lecture
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="video in section.videos" :key="video.youTubeId">
                  <td class="cc-table-top-border">
                    <OutboundLink :href="`https://www.youtube.com/watch?v=${video.youTubeId}`">
                      {{ video.lecture }}
                    </OutboundLink>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div v-if="videos && videos.length" class="cc-widget-webcast-outbound-link">
          <OutboundLink href="http://www.ets.berkeley.edu/find-support/request-forms/request-support-or-give-feedback">Report a problem</OutboundLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import {getWebcasts} from '@/api/canvas'
import CanvasUtils from '@/mixins/CanvasUtils'
import OutboundLink from '@/components/util/OutboundLink'

export default {
  name: 'CourseCaptures',
  components: {OutboundLink},
  mixins: [CanvasUtils],
  data: () => ({
    media: [],
    videos: []
  }),
  created() {
    this.isLoading = true
    this.getCanvasCourseId()
    getWebcasts(this.canvasCourseId).then(response => {
      this.media = response.media
      this.videos = response.videos
      this.isLoading = false
    })
  }
}
</script>

<style scoped lang="scss">
.cc-widget-section-header {
  padding-top: 15px;
}
.cc-webcast-table {
  table {
    tr {
      td, th {
        padding: 5px;
        vertical-align: middle;
      }
    }
  }
}
.cc-widget-webcast-error {
  margin-top: 15px;
}
.cc-widget-webcast-icon-link {
  display: inline;
}
.cc-widget-webcast-links {
  margin-top: 10px;
}
.cc-widget-webcast-select {
  max-width: 300px;
}
.cc-widget-webcast-outbound-link {
  padding: 10px 0 0;
}
.cc-widget-webcast-alert {
  margin: 0 5px 5px 0;
}
</style>
