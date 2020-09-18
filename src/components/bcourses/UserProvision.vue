<template>
  <div class="bc-canvas-application cc-page-user-provision">
    <b-container fluid>
      <b-row no-gutters>
        <h1 class="cc-page-user-provision-heading">Add Users to bCourses</h1>
      </b-row>
      <form name="userImportForm" @submit="onSubmit">
        <b-row no-gutters>
          <b-col cols="10">
            <b-container fluid>
              <b-row no-gutters>
                <b-col cols="2">
                  <label for="cc-page-user-provision-uid-list" class="bc-form-label">
                    <span aria-hidden="true">UID</span>
                    <span class="sr-only">U I D</span>
                    List
                  </label>
                </b-col>
                <b-col cols="10">
                  <textarea
                    id="cc-page-user-provision-uid-list"
                    v-model="rawUids"
                    class="cc-page-user-provision-uid-list-input"
                    rows="4"
                    name="uids"
                    placeholder="Paste your list of UIDs here organized one UID per a line, or separated by spaces or commas."
                  >
                  </textarea>
                  <small v-if="validationErrors.required" role="alert" aria-live="polite">
                    You must provide at least one
                    <span aria-hidden="true">UID</span>
                    <span class="sr-only">U I D</span>
                    .
                  </small>
                  <small v-if="validationErrors.ccNumericList" role="alert" aria-live="polite">
                    The following items in your list are not numeric: {{ invalidValues.join(', ') }}
                  </small>
                  <small v-if="validationErrors.ccListLimit" role="alert" aria-live="polite">
                    Maximum IDs: 200. {{ listLength }} IDs found in list.
                  </small>
                </b-col>
              </b-row>
              <b-row no-gutters>
                <b-col cols="2"></b-col>
                <b-col cols="2">
                  <button
                    type="submit"
                    class="bc-canvas-button bc-canvas-button-primary d-block"
                    :disabled="importButtonDisabled"
                  >
                    Import Users
                  </button>
                </b-col>
                <b-col cols="8">
                  <div role="alert" aria-live="polite">
                    <div v-if="importProcessing" class="cc-spinner">
                      <span class="sr-only">Processing import</span>
                    </div>
                    <div v-if="status === 'error'" class="cc-page-user-provision-feedback">
                      <fa icon="exclamation-circle" class="cc-icon-red mr-2"></fa>
                      <strong>Error : {{ error }}</strong>
                    </div>
                    <div v-if="status === 'success'" class="cc-page-user-provision-feedback">
                      <fa icon="check-circle" class="cc-icon-green mr-2"></fa>
                      Success : The users specified were imported into bCourses.
                    </div>
                  </div>
                </b-col>
              </b-row>
            </b-container>
          </b-col>
        </b-row>
      </form>
    </b-container>
  </div>
</template>

<script>
import {importUsers} from '@/api/canvas'

export default {
  name: 'UserProvision',
  data: () => ({
    error: null,
    importProcessing: false,
    importUsers: () => {},
    invalidValues: [],
    listLength: null,
    rawUids: '',
    status: null,
    validationErrors: {}
  }),
  computed: {
    importButtonDisabled() {
      return this.importProcessing || !this.rawUids.length
    }
  },
  methods: {
    onSubmit(evt) {
      evt.preventDefault()
      this.error = null
      const validatedUids = this.validateUids()
      if (validatedUids) {
        this.importProcessing = true
        this.status = null
        importUsers(validatedUids).then(response => {
          this.importProcessing = false
          this.status = response.status
        }).catch(response => {
          this.importProcessing = false
          this.status = 'error'
          this.error = response.error
        })
      }
    },
    validateUids() {
      this.validationErrors = {}
      this.invalidValues = []
      const uids = this.rawUids.match(/\w+/g)
      if (!uids) {
        this.validationErrors.required = true
      }
      this.listLength = uids.length
      if (this.listLength > 200) {
        this.validationErrors.ccListLimit = true
      }
      this.$_.each(uids, uid => {
        if (isNaN(Number(uid))) {
          this.invalidValues.push(uid)
          this.validationErrors.ccNumericList = true
        }
      })
      if (this.$_.isEmpty(this.validationErrors)) {
        return uids.join()
      }
    }
  }
}
</script>

<style scoped lang="scss">
.cc-page-user-provision {
  color: $bc-color-off-black;
  font-family: $bc-base-font-family;
  font-size: 14px;
  font-weight: 300;
  padding: 10px 20px;

  .cc-page-user-provision-heading {
    font-family: $bc-base-font-family;
    font-size: 23px;
    font-weight: normal;
    margin: 10px 0;
  }

  .cc-page-user-provision-uid-list-input {
    padding: 8px 12px;
  }

  .cc-page-user-provision-feedback {
    padding: 5px 0 15px;
    div {
      margin-top: 5px;
    }
  }

  small {
    font-weight: 300;
  }
}
</style>
