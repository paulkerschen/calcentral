<template>
  <div v-if="!loading" class="bc-page-site-creation">
    <h1 class="bc-header bc-header2 bc-page-site-creation-primary-header">Create a Site</h1>
    <b-container>
      <b-row>
        <b-col sm="3">
          <div class="pl-4">
            <div class="bc-page-site-creation-feature-icon-box">
              <fa
                icon="graduation-cap"
                class="bc-page-site-creation-feature-icon"
                :class="{'bc-page-site-creation-feature-icon-disabled': !canCreateCourseSite}"
              >
              </fa>
            </div>
          </div>
        </b-col>
        <b-col sm="9">
          <div class="bc-page-site-creation-feature-details mr-5 pr-5">
            <h3 class="bc-header bc-header3">Course Sites</h3>
            <div v-if="canCreateCourseSite" class="bc-page-site-creation-feature-description">
              Set up course sites to communicate with and manage the work of students enrolled in your classes.
            </div>
            <div v-if="!canCreateCourseSite" class="bc-page-site-creation-feature-description">
              To create a course site, you will need to be the official instructor of record for a course.
              If you have not been assigned as the official instructor of record for the course,
              please contact your department scheduler.
              You will be able to create a course site the day after you have been officially assigned to teach the course.
            </div>
            <div class="bc-page-site-creation-feature-button-wrapper">
              <a
                id="create-course-site"
                :disabled="!canCreateCourseSite"
                :href="linkToCreateCourseSite"
                class="bc-canvas-button bc-canvas-button-primary"
                :tabindex="canCreateCourseSite ? 0 : -1"
                @click="goCreateCourseSite"
                @keypress="goCreateCourseSite"
              >
                Create a Course Site
              </a>
            </div>
          </div>
        </b-col>
      </b-row>

      <b-row>
        <b-col>
          <div class="bc-page-site-creation-features-divider"></div>
        </b-col>
      </b-row>

      <b-row>
        <b-col sm="3">
          <div class="pl-4">
            <div class="bc-page-site-creation-feature-icon-box">
              <fa icon="cubes" class="bc-page-site-creation-feature-icon"></fa>
            </div>
          </div>
        </b-col>
        <b-col sm="9">
          <div class="bc-page-site-creation-feature-details mr-5 pr-5">
            <h3 class="bc-header bc-header3">Project Sites</h3>
            <div class="bc-page-site-creation-feature-description">
              Share files and collaborate with your team. Projects are best suited for instructors and GSIs who already
              use bCourses.
            </div>
            <div class="bc-page-site-creation-feature-description pt-3">
              Project sites do not have access to all bCourses tools, including assignments, and are not intended for
              lecture, lab, or discussion sections.
              <OutboundLink href="https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0010457">Learn more about collaboration tools available at UC Berkeley.</OutboundLink>
            </div>
            <div class="bc-page-site-creation-feature-button-wrapper">
              <a
                id="create-project-site"
                :disabled="!canCreateProjectSite"
                :tabindex="canCreateProjectSite ? 0 : -1"
                :href="linkToCreateProjectSite"
                class="bc-canvas-button bc-canvas-button-primary"
                @click="goCreateProjectSite"
                @keypress="goCreateProjectSite"
              >
                Create a Project Site
              </a>
            </div>
          </div>
        </b-col>
      </b-row>
    </b-container>
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
    createProjectSiteButtonFocus: undefined,
    linkToCreateCourseSite: undefined,
    linkToCreateProjectSite: undefined
  }),
  created() {
    this.$loading()
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

<style scoped lang="scss">
.bc-page-site-creation {
  background: $cc-color-white;
  padding: 10px 0;

  .bc-page-site-creation-feature-button-wrapper {
    margin-top: 25px;
  }

  .bc-page-site-creation-primary-header {
    margin-bottom: 25px;
    margin-left: 10px;
  }

  .bc-page-site-creation-feature-icon-box {
    background-color: $bc-color-feature-icon-box-background;
    border: $bc-color-feature-icon-box-border solid 1px;
    border-radius: 4px;
    display: table-cell;
    height: 150px;
    text-align: center;
    vertical-align: middle;
    width: 190px;
  }

  .bc-page-site-creation-feature-icon {
    color: $bc-color-headers;
    font-size: 95px;
    margin-left: auto;
    margin-right: auto;
  }

  .bc-page-site-creation-feature-icon-disabled {
    color: $bc-color-feature-icon-color;
  }

  .bc-page-site-creation-feature-description {
    font-weight: 300;
    line-height: 18px;
  }

  .bc-page-site-creation-features-container {
    margin: 0 20px;
  }

  .bc-page-site-creation-features-divider {
    border-top: $bc-color-button-grey-border solid 1px;
    margin: 30px 0;
  }

  @media #{$small-only} {
    .bc-page-site-creation-feature-details {
      text-align: center;
    }
  }
}
</style>
