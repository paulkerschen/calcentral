<template>
  <div class="bc-canvas-application cc-page-user-provision">
    <b-container fluid>
      <b-row no-gutters>
        <h1 class="cc-page-user-provision-heading">Add Users to bCourses</h1>
      </b-row>
      <form name="userImportForm" :submit="importUsers(rawUids)">
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
                  <small v-if="checkPerformed && validationErrors.required" class="error">
                    You must provide at least one
                    <span aria-hidden="true">UID</span>
                    <span class="sr-only">U I D</span>
                    .
                  </small>
                  <small v-if="validationErrors.ccNumericList" class="error">
                    The following items in your list are not numeric: {{ invalidValues.join(', ') }}
                  </small>
                  <small v-if="validationErrors.ccListLimit" class="error">
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
                <b-col v-if="displayImportResult" cols="8">
                  <div data-cc-spinner-directive>
                    <div class="row">
                      <div class="small-11 small-offset-1 columns">
                        <div class="cc-page-user-provision-feedback" role="alert">
                          <div v-if="status === 'error'">
                            <i class="cc-left fa fa-exclamation-circle cc-icon-red"></i>
                            <strong>Error : {{ error }}</strong>
                          </div>
                          <div v-if="status === 'success'">
                            <i class="cc-left fa fa-check-circle cc-icon-green"></i>
                            Success : The users specified were imported into bCourses.
                          </div>
                        </div>
                      </div>
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
export default {
  name: 'UserProvision',
  data: () => ({
    checkPerformed: false,
    error: null,
    importUsers: () => {},
    invalidValues: [],
    rawUids: '',
    status: null,
    validationErrors: {}
  }),
  computed: {
    importButtonDisabled() {
      return !this.rawUids.length
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
    i {
      margin-right: 5px;
    }
    > div {
      margin-top: 5px;
    }
  }
}
</style>