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

      <div v-if="errorMessages" role="alert" class="bc-alert bc-alert-error">
        <div v-for="errorMessage in errorMessages" :key="errorMessage">{{ errorMessage }}</div>
      </div>

      <div v-if="!errorMessages && listCreated" role="alert" class="bc-alert bc-alert-success">
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

      <div v-if="listCreated" class="border-top mt-3 pt-3">
        <h2 id="send-welcome-email-header" class="bc-header bc-page-site-mailing-list-welcome-email-form-heading" tabindex="-1">
          Send Welcome Email
        </h2>
        <b-row no-gutters>
          <p class="bc-page-site-mailing-list-text">
            The Welcome Email tool automatically sends a customizable message by email to all members of your course site, even if the site has not yet been published. For more information, visit <OutboundLink href="https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0013900">https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0013900</OutboundLink>.
          </p>
        </b-row>

        <div v-if="emailFieldsPresent && !isWelcomeEmailActive" role="alert" class="bc-alert bc-alert-warning">
          Sending welcome emails is paused until activation.
        </div>

        <div v-if="alertEmailActivated" role="alert" class="bc-alert bc-alert-success">
          Welcome email activated.
        </div>

        <div v-if="emailFieldsPresent" class="bc-page-site-mailing-list-welcome-email-toggle-outer">
          <label for="welcome-email-activation-toggle" class="bc-page-site-mailing-list-welcome-email-toggle-label">
            Send email:
          </label>
          <div v-if="isWelcomeEmailActive" class="email-status email-status-active toggle-on">
            Active
          </div>
          <div v-if="!isWelcomeEmailActive" class="email-status email-status-paused">
            Paused
          </div>
          <div>
            <button
              v-if="!isTogglingEmailActivation"
              id="welcome-email-activation-toggle"
              type="button"
              class="btn btn-link pt-0 pb-0 pl-1 pr-1"
              @click="toggleEmailActivation"
              @keyup.down="toggleEmailActivation"
            >
              <span class="status-toggle-label">
                <fa v-if="isWelcomeEmailActive" icon="toggle-on" class="toggle toggle-on"></fa>
                <fa v-if="!isWelcomeEmailActive" icon="toggle-off" class="toggle toggle-off"></fa>
              </span>
            </button>
            <div v-if="isTogglingEmailActivation" class="pl-2">
              <fa icon="spinner" spin />
            </div>
          </div>
        </div>

        <div v-if="mailingList.welcomeEmailLastSent" class="bc-page-site-mailing-list-text">
          <b-button
            id="btn-download-sent-message-log"
            type="button"
            variant="link"
            class="p-0"
            @click="downloadMessageLog"
          >
            <fa icon="file-download"></fa>
            Download sent message log (last updated {{ $moment(mailingList.welcomeEmailLastSent).format('MMM D, YYYY') }})
          </b-button>
        </div>

        <form
          v-if="isEditingWelcomeEmail"
          class="bc-canvas-page-form bc-canvas-form bc-page-site-mailing-list-welcome-email-form border-top"
          @submit.prevent="saveWelcomeEmail"
        >
          <b-row no-gutters>
            <label for="bc-page-site-mailing-list-subject-input" class="bc-page-site-mailing-list-welcome-email-form-heading">
              Subject
            </label>
          </b-row>
          <b-row no-gutters>
            <input id="bc-page-site-mailing-list-subject-input" v-model="mailingListSubject" type="text">
          </b-row>
          <b-row no-gutters>
            <label for="bc-page-site-mailing-list-message-input" class="bc-page-site-mailing-list-welcome-email-form-heading">
              Message
            </label>
          </b-row>
          <b-row no-gutters>
            <div id="bc-page-site-mailing-list-message-input" role="textbox" class="w-100 mb-4">
              <ckeditor
                v-model="mailingListMessage"
                class="w-100"
                :config="editorConfig"
                :editor="editor"
              ></ckeditor>
            </div>
          </b-row>
          <b-row no-gutters>
            <button
              id="btn-save-welcome-email"
              type="submit"
              class="bc-canvas-button bc-canvas-button-primary"
              aria-controls="cc-page-reader-alert"
              :disabled="!mailingListSubject || !mailingListMessage"
            >
              <span v-if="!isSavingWelcomeEmail">Save welcome email</span>
              <span v-if="isSavingWelcomeEmail"><fa icon="spinner" class="mr-2 fa-spin"></fa> Saving ...</span>
            </button>
            <button
              id="btn-cancel-welcome-email-edit"
              class="bc-canvas-button bc-canvas-button-secondary"
              type="button"
              @click="cancelEditMode"
            >
              Cancel
            </button>
          </b-row>
        </form>

        <div v-if="!isEditingWelcomeEmail" class="border-top mt-3 pt-3">
          <div class="bc-page-site-mailing-list-welcome-email-field-content">
            <h3 class="bc-header bc-page-site-mailing-list-welcome-email-field-heading">
              Subject
            </h3>
            <div id="bc-page-site-mailing-list-subject">
              {{ mailingList.welcomeEmailSubject }}
            </div>
          </div>
          <div class="bc-page-site-mailing-list-welcome-email-field-content">
            <h3 class="bc-header bc-page-site-mailing-list-welcome-email-field-heading">
              Message
            </h3>
            <div id="bc-page-site-mailing-list-body" class="bc-page-site-mailing-list-welcome-email-body" v-html="mailingList.welcomeEmailBody"></div>
          </div>     
          <div class="bc-page-site-mailing-list-welcome-email-field-content">
            <b-button
              id="btn-edit-welcome-email"
              variant="link"
              class="p-0"
              @click="setEditMode"
            >
              Edit welcome email
            </b-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import {
  activateWelcomeEmail,
  createSiteMailingList,
  deactivateWelcomeEmail,
  downloadWelcomeEmailCsv,
  getSiteMailingList,
  updateWelcomeEmail
} from '@/api/canvas'
import CanvasUtils from '@/mixins/CanvasUtils'
import CKEditor from '@ckeditor/ckeditor5-vue2'
import ClassicEditor from '@ckeditor/ckeditor5-build-classic'
import Context from '@/mixins/Context'
import OutboundLink from '@/components/util/OutboundLink'
import Utils from '@/mixins/Utils'

export default {
  name: 'SiteMailingList',
  components: {
    ckeditor: CKEditor.component,
    OutboundLink
  },
  mixins: [CanvasUtils, Context, Utils],
  data: () => ({
    alertEmailActivated: false,
    alerts: {
      error: [],
      success: []
    },
    editor: ClassicEditor,
    editorConfig: {
      toolbar: ['bold', 'italic', 'bulletedList', 'numberedList', 'link']
    },
    errorMessages: null,
    isCreating: false,
    isEditingWelcomeEmail: false,
    isLoading: false,
    isSavingWelcomeEmail: false,
    isTogglingEmailActivation: false,
    isWelcomeEmailActive: false,
    listCreated: false,
    mailingList: {},
    mailingListMessage: '',
    mailingListSubject: '',
  }),
  computed: {
    emailFieldsPresent() {
      return this.mailingList.welcomeEmailBody && this.mailingList.welcomeEmailSubject
    }
  },
  methods: {
    cancelEditMode() {
      this.isEditingWelcomeEmail = false
      this.isWelcomeEmailActive = this.mailingList.welcomeEmailActive
      this.$putFocusNextTick('send-welcome-email-header')
    },
    createMailingList() {
      this.alertScreenReader('Creating list')
      this.isCreating = true
      createSiteMailingList(this.canvasCourseId, this.mailingList).then(
        response => {
          this.updateDisplay(response)
          this.$ready()
        },
        this.$errorHandler
      )
    },
    downloadMessageLog() {
      this.alertScreenReader('Downloading message log')
      downloadWelcomeEmailCsv(this.canvasCourseId)
    },
    getMailingList() {
      return getSiteMailingList(this.canvasCourseId).then(
        response => {
          this.updateDisplay(response)
          this.$ready()
        },
        this.$errorHandler
      )
    },
    saveWelcomeEmail() {
      this.alertScreenReader('Saving welcome email')
      this.savingWelcomeEmail = true
      updateWelcomeEmail(this.canvasCourseId, this.mailingListSubject, this.mailingListMessage).then(
        response => {
          this.updateDisplay(response)
          this.$putFocusNextTick('send-welcome-email-header')
        },
        this.$errorHandler
      )
    },
    setEditMode() {
      this.alertEmailActivated = false
      this.isEditingWelcomeEmail = true
      this.$putFocusNextTick('bc-page-site-mailing-list-subject-input')
    },
    toggleEmailActivation() {
      this.alertEmailActivated = false
      this.isTogglingEmailActivation = true
      const toggleEmailActivation = this.isWelcomeEmailActive ? deactivateWelcomeEmail : activateWelcomeEmail
      toggleEmailActivation(this.canvasCourseId).then((data) => {
        this.isWelcomeEmailActive = !!data.welcomeEmailActive
        this.isTogglingEmailActivation = false
        if (this.isWelcomeEmailActive) {
          this.alertEmailActivated = true
        }
        this.alertScreenReader(`${this.isWelcomeEmailActive ? 'Actived' : 'Paused' } welcome email`)
      })
    },
    updateDisplay(data) {
      this.mailingList = data.mailingList || {}
      this.isWelcomeEmailActive = this.mailingList.welcomeEmailActive
      this.mailingListMessage = this.mailingList.welcomeEmailBody
      this.mailingListSubject = this.mailingList.welcomeEmailSubject
      this.errorMessages = data.errorMessages
      this.listCreated = (data.mailingList && data.mailingList.state === 'created')
      if (this.listCreated && (!this.mailingListMessage && !this.mailingListSubject)) {
        this.isEditingWelcomeEmail = true
      } else {
        this.isEditingWelcomeEmail = false
      }
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

<style>
.ck.ck-editor__editable_inline {
  min-height: 150px;
  padding: 0 15px;
}
.ck.ck-editor__editable_inline ol {
  margin: 0 0 10px 20px;
}
.ck.ck-editor__editable_inline p {
  margin: 0 0 10px 0;
}
.ck.ck-editor__editable_inline ul {
  list-style-type: disc;
  margin: 0 0 10px 20px;
}
.bc-page-site-mailing-list-welcome-email-body ol {
  margin: 0 0 10px 20px;
}
.bc-page-site-mailing-list-welcome-email-body p {
  margin: 0 0 10px 0;
}
.bc-page-site-mailing-list-welcome-email-body ul {
  list-style-type: disc;
  margin: 0 0 10px 20px;
}
</style>

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

  .bc-page-site-mailing-list-welcome-email-form {
    margin: 15px 15px 0 0;
    padding: 15px 0 0 15px;
  }

  .bc-page-site-mailing-list-welcome-email-body ol {
    margin-left: 20px;
  }

  .bc-page-site-mailing-list-welcome-email-body ul {
    margin-left: 20px;
  }

  .bc-page-site-mailing-list-welcome-email-field-content {
    font-size: 14px;
    font-weight: 300;
    line-height: 1.6;
    margin: 0 0 15px 15px;
  }

  .bc-page-site-mailing-list-welcome-email-field-heading {
    font-size: 18px;
    font-weight: 600;
    line-height: 1.6;
    margin: 0 0 5px 0;
    padding: 0;
  }

  .bc-page-site-mailing-list-welcome-email-form-heading {
    font-size: 18px;
    font-weight: 600;
  }

  .bc-page-site-mailing-list-welcome-email-toggle-label {
    font-size: 14px;
    font-weight: 600;
    padding-right: 15px;
  }

  .bc-page-site-mailing-list-welcome-email-toggle-outer {
    display: flex;
    margin: 15px;
  }

  .email-status {
    font-size: 12px;
    text-transform: uppercase;
  }

  .email-status-active {
    font-weight: 600;
  }

  .email-status-paused {
    color: #999999;
  }

  .toggle {
    font-size: 20px;
  }

  .toggle-off {
    color: #999999;
  }

  .toggle-on {
    color: #00c13a;
  }
}
</style>
