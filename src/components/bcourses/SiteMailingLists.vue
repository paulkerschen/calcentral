<template>
  <div class="bc-canvas-application bc-page-site-mailing-list">
    <h1 class="bc-header bc-header1">Manage a Site Mailing List</h1>
    <div v-if="alerts.error.length" role="alert" class="bc-alert bc-alert-error">
      <fa icon="exclamation-triangle" class="cc-icon cc-left bc-icon-red bc-canvas-notice-icon"></fa>
      <div class="bc-page-site-mailing-list-notice-message">
        <div v-for="error in alerts.error" :key="error">{{ error }}</div>
      </div>
    </div>

    <div v-if="alerts.success.length" role="alert" class="bc-alert bc-alert-success">
      <fa icon="check-circle" class="cc-icon cc-left bc-icon-green bc-canvas-notice-icon"></fa>
      <div class="bc-page-site-mailing-list-notice-message">
        <div v-for="success in alerts.success" :key="success">{{ success }}</div>
      </div>
    </div>

    <div v-if="listCreated && !mailingList.timeLastPopulated" role="alert" class="bc-alert bc-alert-info">
      The list <strong>"{{ mailingList.name }}@{{ mailingList.domain }}"</strong> has been created. Choose "Update membership from course site" to add members.
    </div>

    <div v-if="siteSelected && !listCreated" role="alert" class="bc-alert bc-alert-info">
      No mailing list has been created for this site.
    </div>

    <div v-if="!siteSelected">
      <form class="bc-page-site-mailing-list-form" @submit.prevent="findSiteMailingList">
        <b-row no-gutters>
          <b-col sm="12" md="3">
            <label for="bc-page-site-mailing-list-site-id" class="bc-page-site-mailing-list-form-label">Course Site ID:</label>
          </b-col>
          <b-col sm="12" md="6">
            <input 
              id="bc-page-site-mailing-list-site-id" 
              v-model="canvasSite.canvasCourseId"
              type="text"
              class="cc-left bc-canvas-form-input-text"
              placeholder="Enter numeric site ID"
              required
              aria-required="true"
            >
            <button 
              id="btn-get-mailing-list"
              type="submit"
              class="bc-canvas-button bc-canvas-button-primary"
              :disabled="isProcessing || !canvasSite.canvasCourseId"
            >
              <span v-if="!isProcessing">Get Mailing List</span>
              <span v-if="isProcessing"><i class="fa fa-spinner fa-spin"></i> Finding ...</span>
            </button>
          </b-col>
        </b-row>
      </form>
    </div>

    <div v-if="siteSelected">
      <div id="mailing-list-details" class="bc-page-site-mailing-list-info-box">
        <h2 id="mailing-list-details-header" class="bc-header bc-page-site-mailing-list-header2" tabindex="-1">
          <span v-if="!listCreated" class="cc-ellipsis">{{ canvasSite.name }}</span>
          <span v-if="listCreated" class="cc-ellipsis">{{ mailingList.name }}@{{ mailingList.domain }}</span>
        </h2>
        <div v-if="listCreated">
          <div id="mailing-list-member-count">{{ pluralize('member', mailingList.membersCount, {0: 'No'}) }}</div>
          <div>Membership last updated: <strong id="mailing-list-membership-last-updated">{{ listLastPopulated }}</strong></div>
          <div>
            Course site:
            <OutboundLink
              id="mailing-list-court-site-name"
              :href="canvasSite.url"
              @click="trackExternalLink('Canvas Site Mailing List', 'bCourses', canvasSite.url)"
            >
              {{ canvasSite.name }}  
            </OutboundLink>
          </div>
        </div>
        <b-row no-gutters>
          <b-col id="mailing-list-canvas-code-and-term" sm="12" md="4">{{ canvasSite.codeAndTerm }}</b-col>
          <b-col id="mailing-list-canvas-course-id" sm="12" md="6">Site ID: {{ canvasSite.canvasCourseId }}</b-col>
        </b-row>
        <OutboundLink
          v-if="!listCreated"
          id="view-course-site-link"
          :href="canvasSite.url"
          @click="trackExternalLink('Canvas Site Mailing List', 'bCourses', canvasSite.url)"
        >
          View course site
        </OutboundLink>
      </div>

      <form class="bc-canvas-page-form bc-canvas-form">
        <div v-if="!listCreated">
          <b-row no-gutters class="bc-page-site-mailing-list-form-input-row">
            <b-col sm="12" md="3">
              <label for="mailingListName" class="bc-page-site-mailing-list-form-label">New Mailing List Name:</label>
            </b-col>
            <b-col sm="12" md="9">
              <input
                id="mailingListName"
                v-model="mailingList.name"
                type="text"
                class="cc-left bc-canvas-form-input-text"
                required
                aria-required="true"
              />
            </b-col>
          </b-row>
        </div>

        <div class="bc-form-actions">
          <button
            v-if="!listCreated"
            id="btn-create-mailing-list"
            type="button"
            class="bc-canvas-button bc-canvas-button-primary"
            aria-controls="cc-page-reader-alert"
            @click="registerMailingList"
          >
            <span>Create mailing list</span>
          </button>
          <button
            v-if="listCreated"
            id="btn-populate-mailing-list"
            type="button"
            class="bc-canvas-button bc-canvas-button-primary"
            aria-controls="cc-page-reader-alert"
            @click="populateMailingList"
          >
            <span v-if="!isProcessing">Update membership from course site</span>
            <span v-if="isProcessing"><fa icon="spinner" class="mr-2 fa-spin"></fa> Updating ...</span>
          </button>
          <button 
            id="btn-cancel"
            type="button"
            class="bc-canvas-button"
            @click="resetForm"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import {createSiteMailingListAdmin, getSiteMailingListAdmin, populateSiteMailingList} from '@/api/canvas'
import Context from '@/mixins/Context'
import OutboundLink from '@/components/util/OutboundLink'
import Utils from '@/mixins/Utils'

export default {
  name: 'SiteMailingLists',
  components: {OutboundLink},
  mixins: [Context, Utils],
  data: () => ({
    alerts: {
      error: [],
      success: []
    },
    canvasSite: {},
    isProcessing: false,
    listCreated: false,
    listLastPopulated: null,
    mailingList: {},
    siteSelected: false
  }),
  methods: {
    findSiteMailingList() {
      this.isProcessing = true
      getSiteMailingListAdmin(this.canvasSite.canvasCourseId).then(
        response => {
          this.updateDisplay(response)
        },
        this.$errorHandler
      )
    },
    populateMailingList() {
      this.alertScreenReader('Updating membership')
      this.isProcessing = true
      populateSiteMailingList(this.canvasSite.canvasCourseId).then(
        response => {
          this.updateDisplay(response)
          if (!response || !response.populationResults) {
            this.alerts.error.push('The mailing list could not be populated.')
          }
        },
        this.$errorHandler
      )
    },
    registerMailingList() {
      this.alertScreenReader('Creating list')
      this.isProcessing = true
      createSiteMailingListAdmin(this.canvasSite.canvasCourseId, this.mailingList).then(
        response => {
          this.updateDisplay(response)
        },
        this.$errorHandler
      )
    },
    resetForm() {
      this.canvasSite = {}
      this.mailingList = {}
      this.updateDisplay({})
      this.alertScreenReader('Canceled.')
      this.putFocusNextTick('bc-page-site-mailing-list-site-id')
    },
    trackExternalLink() {
      // TODO implement CLC-7512
    },
    updateCodeAndTerm(canvasSite) {
      const codeAndTermArray = []
      if (canvasSite.courseCode !== canvasSite.name) {
        codeAndTermArray.push(canvasSite.courseCode)
      }
      if (canvasSite.term && canvasSite.term.name) {
        codeAndTermArray.push(canvasSite.term.name)
      }
      canvasSite.codeAndTerm = codeAndTermArray.join(', ')
    },
    updateDisplay(data) {
      this.alerts.success = []
      this.alerts.error = data.errorMessages || []
      this.canvasSite = data.canvasSite || {}
      this.mailingList = data.mailingList || {}
      this.siteSelected = !!this.$_.get(data, 'canvasSite.canvasCourseId')
      this.listCreated = (this.$_.get(data, 'mailingList.state') === 'created')
      if (this.siteSelected) {
        this.updateCodeAndTerm(this.canvasSite)
        this.$putFocusNextTick('mailing-list-details-header')
      }
      if (this.listCreated) {
        this.updateListLastPopulated(this.mailingList)
      }
      if (data.populationResults) {
        this.updatePopulationResults(data.populationResults)
      }
      this.isProcessing = false
    },
    updateListLastPopulated(mailingList) {
      if (mailingList.timeLastPopulated) {
        this.listLastPopulated = this.$moment.unix(mailingList.timeLastPopulated.epoch).format('MMM D, YYYY')
      } else {
        this.listLastPopulated = 'never'
      }
    },
    updatePopulationResults(populationResults) {
      if (populationResults.success) {
        this.alerts.success.push('Memberships were successfully updated.')
        if (populationResults.messages.length) {
          this.alerts.success = this.alerts.success.concat(populationResults.messages)
        } else {
          this.alerts.success.push('No changes in membership were found.')
        }
      } else {
        this.alerts.error.push('There were errors during the last membership update.')
        this.alerts.error = this.alerts.error.concat(populationResults.messages)
        this.alerts.error.push('You can attempt to correct the errors by running the update again.')
      }
    }
  },
  mounted() {
    this.$ready()
  }
}
</script>

<style scoped lang="scss">
.bc-page-site-mailing-list {
  padding: 20px;

  .bc-page-site-mailing-list-button-primary {
    margin: 0 4px;
  }

  .bc-page-site-mailing-list-header2 {
    font-size: 17px;
    line-height: 25px;
  }

  .bc-page-site-mailing-list-header3 {
    font-size: 15px;
    line-height: 22px;
  }

  .bc-page-site-mailing-list-info-box {
    border: 1px solid $bc-color-container-grey-border;
    margin: 24px 0;
    padding: 6px 10px;
  }

  .bc-page-site-mailing-list-form {
    margin: 20px 0;
  }

  .bc-page-site-mailing-list-form-input-row {
    margin: 20px 0;
    text-align: right;
  }

  .bc-page-site-mailing-list-form-label {
    text-align: right;
  }

  .bc-page-site-mailing-list-form-label-long {
    display: inline;
    font-weight: 300;
    text-align: left;
  }

  .bc-page-site-mailing-list-notice-message {
    margin-left: 30px;
  }

  .bc-page-site-mailing-list-text {
    font-size: 14px;
    font-weight: 300;
    line-height: 1.6;
    margin: 15px;
  }

  @media #{$small-only} {
    .bc-page-site-mailing-list-form-label {
      text-align: left;
    }
  }
}
</style>