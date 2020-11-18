<template>
  <div>
    <div class="bc-alert bc-alert-info" role="alert">
      <h2 class="cc-visuallyhidden">Confirm Course Site Details</h2>
      <strong>
        You are about to create a {{ currentSemesterName }} course site with {{ pluralize('section', selectedSectionsList.length) }}:
      </strong>
      <ul class="bc-page-create-course-site-section-list">
        <li v-for="section in selectedSectionsList" :key="section.ccn">
          {{ section.courseTitle }} - {{ section.courseCode }} {{ section.section_label }} ({{ section.ccn }})
        </li>
      </ul>
    </div>
    <div>
      <form
        name="createCourseSiteForm"
        class="bc-canvas-page-form"
        @submit.prevent="create"
      >
        <b-container fluid>
          <b-row>
            <b-col class="pr-1" md="3">
              <label for="siteName" class="right">
                Site Name:
              </label>
            </b-col>
            <b-col class="pl-0" md="6">
              <b-form-input
                id="siteName"
                v-model="siteName"
                class="w-100"
                name="siteName"
                :required="true"
              />
              <div v-if="!$_.trim(siteName)" class="bc-alert bc-notice-error">
                <fa icon="exclamation-circle" class="cc-left cc-icon-red bc-canvas-notice-icon"></fa>
                Please fill out a site name.
              </div>
            </b-col>
          </b-row>
          <b-row>
            <b-col class="pr-1" md="3">
              <label for="siteAbbreviation" class="right">Site Abbreviation:</label>
            </b-col>
            <b-col class="pl-0" md="6">
              <b-form-input
                id="siteAbbreviation"
                v-model="siteAbbreviation"
                class="w-100"
                :required="true"
              />
              <div v-if="!$_.trim(siteAbbreviation)" class="bc-alert bc-notice-error">
                <fa icon="exclamation-circle" class="cc-left cc-icon-red bc-canvas-notice-icon"></fa>
                Please fill out a site abbreviation.
              </div>
            </b-col>
          </b-row>
        </b-container>
        <div class="d-flex flex-row-reverse">
          <div>
            <b-button
              id="create-course-site-button"
              type="submit"
              aria-controls="bc-page-create-course-site-steps-container"
              aria-label="Create Course Site"
              class="bc-canvas-button bc-canvas-button-primary"
              :disabled="!$_.trim(siteName) || !$_.trim(siteAbbreviation)"
            >
              Create Course Site
            </b-button>
          </div>
          <div class="pr-2">
            <b-button
              id="go-back-button"
              class="bc-canvas-button"
              @click="goBack"
            >
              Go Back
            </b-button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Iframe from '@/mixins/Iframe'
import Utils from '@/mixins/Utils'

export default {
  name: 'ConfirmationStep',
  mixins: [Context, Iframe, Utils],
  props: {
    currentSemesterName: {
      required: true,
      type: String
    },
    goBack: {
      required: true,
      type: Function
    },
    selectedSectionsList: {
      required: true,
      type: Array
    },
    startCourseSiteJob: {
      required: true,
      type: Function
    }
  },
  data: () => ({
    siteAbbreviation: undefined,
    siteName: undefined
  }),
  created() {
    const section = this.selectedSectionsList[0]
    this.siteName = `${section.courseTitle} (${this.currentSemesterName})`
    this.siteAbbreviation = `${section.courseCode}-${section.instruction_format}-${section.section_number}`
    this.iframeScrollToTop()
    this.$putFocusNextTick('siteName')
    this.alertScreenReader('Confirm the course site name.')
  },
  methods: {
    create() {
      this.startCourseSiteJob(this.siteName, this.siteAbbreviation)
    }
  }
}
</script>

<style scoped lang="scss">
.bc-page-create-course-site-section-list {
  list-style-type: disc;
  margin: 10px 0 0 39px;
}
</style>
