<template>
  <!-- TODO: data-cc-spinner-directive -->
  <div class="bc-canvas-application bc-page-create-project-site" data-cc-spinner-directive>
    <div v-if="!displayError">
      <h1 class="bc-header bc-header2">Create a Project Site</h1>
      <div
        v-if="creatingSite"
        id="cc-page-reader-alert"
        role="alert"
        aria-live="polite"
        class="cc-visuallyhidden"
      >
        {{ actionStatus }}
      </div>
      <form class="bc-canvas-page-form bc-canvas-form">
        <div class="row bc-page-create-project-site-form-fields">
          <div class="small-12 medium-3 columns">
            <div class="bc-page-create-project-site-form-area-container">
              <label for="bc-page-create-project-site-name" class="bc-page-create-project-site-form-label">Project Site Name</label>
            </div>
          </div>
          <div class="small-12 medium-4 columns end">
            <div class="bc-page-create-project-site-form-area-container">
              <b-form-input
                id="bc-page-create-project-site-name"
                v-model="projectSiteName"
                type="text"
                name="projectSiteName"
                :disabled="creatingSite"
                placeholder="Enter a name for your site"
                class="bc-canvas-form-input-text"
              />
            </div>
          </div>
        </div>

        <div class="bc-form-actions">
          <button
            :disabled="disableSubmit"
            aria-controls="cc-page-reader-alert"
            class="bc-canvas-button bc-canvas-button-primary"
            type="submit"
            @click="createProjectSite"
          >
            <span v-if="!creatingSite">Create a Project Site</span>
            <span v-if="creatingSite"><fa icon="spinner" spin></fa> Creating ...</span>
          </button>
          <a
            id="link-to-site-overview"
            :href="linkToSiteOverview"
            class="bc-canvas-button"
            type="reset"
            aria-label="Cancel and return to Site Creation Overview"
          >
            Cancel
          </a>
        </div>
      </form>
    </div>
    <div v-if="displayError" class="bc-alert-container">
      <CanvasErrors :display-error="displayError" />
    </div>
  </div>
</template>

<script>
import CanvasErrors from '@/components/bcourses/CanvasErrors'

export default {
  name: 'CreateProjectSite',
  components: {CanvasErrors},
  data: () => ({
    actionStatus: undefined,
    creatingSite: undefined,
    disableSubmit: true,
    displayError: undefined,
    linkToSiteOverview: undefined,
    projectSiteName: undefined
  }),
  methods: {
    createProjectSite() {
      // TODO
    }
  }
}
</script>
