<template>
  <div v-if="!loading" class="bc-page-site-creation">
    <div>
      <h2 class="bc-header bc-header2 bc-page-site-creation-primary-header">Create a Site</h2>
      <div class="row">
        <div class="small-12 medium-3 columns">
          <div class="bc-page-site-creation-feature-icon-container">
            <div class="bc-page-site-creation-feature-icon-box">
              <fa
                icon="graduation-cap"
                class="bc-page-site-creation-feature-icon"
                :class="{'bc-page-site-creation-feature-icon-disabled': !canCreateCourseSite}"
              >
              </fa>
            </div>
          </div>
        </div>

        <div class="small-12 medium-5 columns end">
          <div class="bc-page-site-creation-feature-details">
            <h3 class="bc-header bc-header3">Course Sites</h3>
            <p v-if="canCreateCourseSite" class="bc-page-site-creation-feature-description">
              Set up course sites to communicate with and manage the work of students enrolled in your classes.
            </p>
            <p v-if="!canCreateCourseSite" class="bc-page-site-creation-feature-description">
              To create a course site, you will need to be the official instructor of record for a course.
              If you have not been assigned as the official instructor of record for the course,
              please contact your department scheduler.
              You will be able to create a course site the day after you have been officially assigned to teach the course.
            </p>
            <div class="bc-page-site-creation-feature-button-wrapper">
              <a
                id="create-course-site"
                :disabled="!canCreateCourseSite"
                :href="linkToCreateCourseSite"
                class="bc-canvas-button bc-canvas-button-primary"
                :tabindex="createCourseSiteButtonFocus"
                @click="goCreateCourseSite"
              >
                Create a Course Site
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class="row">
        <div class="small-12 medium-8 columns">
          <div class="bc-page-site-creation-features-divider-wrapper">
            <div class="bc-page-site-creation-features-divider"></div>
          </div>
        </div>
      </div>

      <div class="row">
        <div class="small-12 medium-3 columns">
          <div class="bc-page-site-creation-feature-icon-container">
            <div class="bc-page-site-creation-feature-icon-box">
              <fa icon="cubes" class="bc-page-site-creation-feature-icon"></fa>
            </div>
          </div>
        </div>

        <div class="small-12 medium-5 columns end">
          <div class="bc-page-site-creation-feature-details">
            <h3 class="bc-header bc-header3">Project Sites</h3>
            <p class="bc-page-site-creation-feature-description">
              Share files and collaborate with your team. Projects are best suited for instructors and GSIs who already
              use bCourses.
            </p>
            <p class="bc-page-site-creation-feature-description">
              Project sites do not have access to all bCourses tools, including assignments, and are not intended for
              lecture, lab, or discussion sections.
              <OutboundLink href="https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0010457">Learn more about collaboration tools available at UC Berkeley.</OutboundLink>
            </p>
            <div class="bc-page-site-creation-feature-button-wrapper">
              <a
                id="create-project-site"
                :disabled="!canCreateProjectSite"
                :tabindex="createProjectSiteButtonFocus"
                :href="linkToCreateProjectSite"
                class="bc-canvas-button bc-canvas-button-primary"
                @click="goCreateProjectSite"
              >
                Create a Project Site
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import OutboundLink from '@/components/util/OutboundLink'
import Util from '@/mixins/Utils'
import {getSiteCreationAuthorizations} from '@/api/canvas'

export default {
  name: 'SiteCreation',
  mixins: [Context, Util],
  components: {OutboundLink},
  data: () => ({
    canCreateCourseSite: undefined,
    canCreateProjectSite: undefined,
    createCourseSiteButtonFocus: undefined,
    createProjectSiteButtonFocus: undefined,
    linkToCreateCourseSite: undefined,
    linkToCreateProjectSite: undefined
  }),
  created() {
    getSiteCreationAuthorizations().then(data => {
      this.canCreateCourseSite = data.authorizations.canCreateCourseSite
      this.canCreateProjectSite = data.authorizations.canCreateProjectSite
      this.$ready()
    })
  },
  methods: {
    goCreateCourseSite() {
      this.$router.push({ path: '/canvas/create_course_site' })
    },
    goCreateProjectSite() {
      this.$router.push({ path: '/canvas/create_project_site' })
    }
  }
}
</script>

<style scoped>

</style>
