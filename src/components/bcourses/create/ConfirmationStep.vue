<template>
  <div>
    <div>
      <div class="medium-12 columns">
        <div class="bc-alert bc-alert-info" role="alert">
          <!-- TODO: data-cc-focus-reset-directive -->
          <h2 class="cc-visuallyhidden" data-cc-focus-reset-directive="confirmFocus">Confirm Course Site Details</h2>
          <strong>
            You are about to create a {{ currentSemesterName }} course site with
            {{ selectedSections(coursesList).length }}
            {{ pluralize(section, selectedSections(coursesList).length) }}:
          </strong>
          <ul class="bc-page-create-course-site-section-list">
            <li v-for="section in selectedSections(coursesList)" :key="section.ccn">
              {{ section.courseTitle }} - {{ section.courseCode }}
              {{ section.section_label }} ({{ section.ccn }})
            </li>
          </ul>
        </div>
      </div>
    </div>
    <div>
      <div class="medium-12 columns">
        <form
          name="createCourseSiteForm"
          class="bc-canvas-page-form"
          @submit="createCourseSiteJob"
        >
          <div>
            <div class="small-12 medium-6 end">
              <div class="bc-page-create-course-site-form-fields-container">
                <div>
                  <div class="medium-offset-1 medium-4 columns">
                    <label for="siteName" class="right">Site Name:</label>
                  </div>
                  <div class="medium-7 columns">
                    <b-form-input
                      id="siteName"
                      v-model="siteName"
                      type="text"
                      name="siteName"
                      :required="true"
                    />
                    <div v-if="createCourseSiteForm.siteName.$error.required" class="bc-alert bc-notice-error">
                      <fa icon="exclamation-circle" class="cc-left cc-icon-red bc-canvas-notice-icon"></fa>
                      Please fill out a site name.
                    </div>
                  </div>
                </div>
                <div>
                  <div class="medium-offset-1 medium-4 columns">
                    <label for="siteAbbreviation" class="right">Site Abbreviation:</label>
                  </div>
                  <div class="medium-7 columns">
                    <b-form-input
                      id="siteAbbreviation"
                      v-model="siteAbbreviation"
                      type="text"
                      name="siteAbbreviation"
                      :required="true"
                    />
                    <div v-if="createCourseSiteForm.siteAbbreviation.$error.required" class="bc-alert bc-notice-error">
                      <fa icon="exclamation-circle" class="cc-left cc-icon-red bc-canvas-notice-icon"></fa>
                      Please fill out a site abbreviation.
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div>
            <div class="medium-12 columns">
              <div class="bc-form-actions">
                <button
                  :disabled="createCourseSiteForm.$invalid"
                  class="bc-canvas-button bc-canvas-button-primary"
                  type="submit"
                  role="button"
                  aria-label="Create Course Site"
                  aria-controls="bc-page-create-course-site-steps-container"
                >
                  Create Course Site
                </button>
                <button class="bc-canvas-button" type="button" @click="showSelecting">Go Back</button>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ConfirmationStep',
  props: {
    selectedSections: {
      required: true,
      type: Array
    }
  }
}
</script>

<style scoped lang="scss">
.bc-page-create-course-site-section-list {
  list-style-type: disc;
  margin: 10px 0 0 39px;
}

.bc-page-create-course-site-form-fields-container {
  margin: 10px 0;
}
</style>
