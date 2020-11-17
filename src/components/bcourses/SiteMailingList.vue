<template>
  <div class="bc-canvas-application bc-page-site-mailing-list">
    <div v-if="isLoading" class="cc-spinner"></div>

    <div v-if="!isLoading">
      <h1 class="bc-header bc-header1">Mailing List</h1>

      <div v-if="alerts.error.length" role="alert" class="bc-alert bc-alert-error">
        <fa icon="exclamation-triangle" class="cc-icon cc-left bc-icon-red bc-canvas-notice-icon"></fa>
        <div class="bc-page-site-mailing-list-notice-message">
          <div v-for="error in alerts.error" :key="error">{{ error }}</div>
        </div>
      </div>

      <div v-if="errorMessages" class="bc-alert bc-alert-error">
        <div v-for="errorMessage in errorMessages" :key="errorMessage">{{ errorMessage }}</div>
      </div>

      <div v-if="!errorMessages && listCreated" class="bc-alert bc-alert-success">
        A Mailing List has been created at <strong>{{ mailingList.name }}@{{ mailingList.domain }}</strong>.
        Messages can now be sent through this address.
      </div>

      <div v-if="!errorMessages && !listCreated" class="bc-alert">
        No Mailing List has yet been created for this site.
      </div>

      <p class="bc-page-site-mailing-list-text">
        bCourses Mailing Lists allow Teachers, TAs, Lead TAs and Readers to send email to everyone in a bCourses site by
        giving the site its own email address. Messages sent to this address from the
        <strong>official berkeley.edu email address</strong>
        of a Teacher, TA, Lead TA or Reader will be sent to the official email addresses of all site
        members. Students and people not in the site cannot send messages through Mailing Lists.
      </p>

      <form v-if="!listCreated" class="bc-canvas-page-form bc-canvas-form" @submit.prevent="createMailingList">
        <div class="bc-form-actions">
          <button
            id="btn-create-mailing-list"
            type="submit"
            class="bc-canvas-button bc-canvas-button-primary"
            aria-controls="cc-page-reader-alert"
            :disabled="errorMessages"
          >
            <span v-if="!isCreating">Create mailing list</span>
            <span v-if="isCreating"><fa icon="spinner" class="mr-2 fa-spin"></fa> Creating ...</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import {createSiteMailingList, getSiteMailingList} from '@/api/canvas'
import CanvasUtils from '@/mixins/CanvasUtils'
import Utils from '@/mixins/Utils'

export default {
  name: 'SiteMailingList',
  mixins: [CanvasUtils, Utils],
  data: () => ({
    alerts: {
      error: [],
      success: []
    },
    errorMessages: null,
    isCreating: false,
    isLoading: false,
    listCreated: false,
    mailingList: {},
  }),
  methods: {
    createMailingList() {
      this.isCreating = true
      createSiteMailingList(this.canvasCourseId, this.mailingList).then(
        response => {
          this.updateDisplay(response)
        },
        this.$errorHandler
      )
    },
    getMailingList() {
      return getSiteMailingList(this.canvasCourseId).then(
        response => {
          this.updateDisplay(response)
        },
        this.$errorHandler
      )
    },
    updateDisplay(data) {
      this.mailingList = data.mailingList || {}
      this.errorMessages = data.errorMessages
      this.listCreated = (data.mailingList && data.mailingList.state === 'created')
      this.isCreating = false
      this.isLoading = false
    }
  },
  created() {
    this.isLoading = true
    this.getCanvasCourseId()
    this.getMailingList()
  }
}
</script>

<style scoped lang="scss">
.bc-page-site-mailing-list {
  padding: 20px;

  .bc-page-site-mailing-list-notice-message {
    margin-left: 30px;
  }

  .bc-page-site-mailing-list-text {
    font-size: 14px;
    font-weight: 300;
    line-height: 1.6;
    margin: 15px;
  }
}
</style>
