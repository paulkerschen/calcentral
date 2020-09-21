<template>
  <div class="bc-canvas-application bc-page-site-mailing-list">
    <h1 class="bc-header bc-header1">Manage a Site Mailing List</h1>
    <div v-if="alerts.error.length" role="alert" class="bc-alert bc-alert-error">
      <i class="fa fa-error fa-exclamation-triangle cc-left bc-icon-red bc-canvas-notice-icon"></i>
      <div class="bc-page-site-mailing-list-notice-message">
        <div v-for="error in alerts.error" :key="error">{{ error }}</div>
      </div>
    </div>

    <div v-if="alerts.success.length" role="alert" class="bc-alert bc-alert-success">
      <fa icon="check-circle" class="cc-left bc-icon-green bc-canvas-notice-icon"></fa>
      <div class="bc-page-site-mailing-list-notice-message">
        <div v-for="success in alerts.success" :key="success">{{ success }}</div>
      </div>
    </div>

    <div v-if="listCreated && !mailingList.timeLastPopulated" class="bc-alert bc-alert-info">
      The list <strong>"{{ mailingList.name }}@{{ mailingList.domain }}"</strong> has been created. Choose "Update membership from course site" to add members.
    </div>

    <div v-if="!siteSelected">
      <form class="bc-page-site-mailing-list-form">
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
            <button class="bc-canvas-button bc-canvas-button-primary" :disabled="isProcessing || !canvasSite.canvasCourseId" @click="findSiteMailingList">
              <span v-if="!isProcessing">Get Mailing List</span>
              <span v-if="isProcessing"><i class="fa fa-spinner fa-spin"></i> Finding ...</span>
            </button>
          </b-col>
        </b-row>
      </form>
    </div>

    <div v-if="siteSelected">
      <div class="bc-page-site-mailing-list-info-box">
        <h2 class="bc-header bc-page-site-mailing-list-header2">
          <span v-if="!listCreated" class="cc-ellipsis">{{ canvasSite.name }}</span>
          <span v-if="listCreated" class="cc-ellipsis">{{ mailingList.name }}@{{ mailingList.domain }}</span>
        </h2>
        <div v-if="listCreated">
          <div>{{ mailingList.membersCount || 0 }} member(s)</div>
          <div>Membership last updated: <strong>{{ listLastPopulated }}</strong></div>
          <div>
            Course site:
            <a :href="canvasSite.url" @click="trackExternalLink('Canvas Site Mailing List', 'bCourses', canvasSite.url)">
              {{ canvasSite.name }}  
            </a>
          </div>
        </div>
        <b-row no-gutters>
          <b-col sm="12" md="4">{{ canvasSite.codeAndTerm }}</b-col>
          <b-col sm="12" md="6">Site ID: {{ canvasSite.canvasCourseId }}</b-col>
        </b-row>
        <a v-if="!listCreated" :href="canvasSite.url" @click="trackExternalLink('Canvas Site Mailing List', 'bCourses', canvasSite.url)">
          View course site
        </a>
      </div>

      <div v-if="!listCreated" class="bc-page-site-mailing-list-text">
        No mailing list has been created for this site.
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
            class="bc-canvas-button bc-canvas-button-primary"
            aria-controls="cc-page-reader-alert"
            @click="registerMailingList"
          >
            <span>Create mailing list</span>
          </button>
          <button
            v-if="listCreated"
            class="bc-canvas-button bc-canvas-button-primary"
            aria-controls="cc-page-reader-alert"
            @click="populateMailingList"
          >
            <span v-if="!isProcessing">Update membership from course site</span>
            <span v-if="isProcessing"><i class="fa fa-spinner fa-spin"></i> Updating ...</span>
          </button>
          <button class="bc-canvas-button" @click="resetForm">Cancel</button>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SiteMailingLists',
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
      // TODO implement
    },
    populateMailingList() {
      // TODO implement
    },
    registerMailingList() {
      // TODO implement
    },
    resetForm() {
      // TODO implement
    },
    trackExternalLink() {
      // TODO implement
    }
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