<template>
  <div class="bc-canvas-application cc-page-user-provision">
    <b-container fluid>
      <b-row>
        <h1 class="cc-page-user-provision-heading">Add Users to bCourses</h1>
      </b-row>
      <b-row>
        <form name="userImportForm" :submit="importUsers(rawUids)">
          <b-col cols="10">
            <div class="row">
              <div class="small-2 columns">
                <label for="cc-page-user-provision-uid-list" class="bc-form-label">
                  <span aria-hidden="true">UID</span>
                  <span class="sr-only">U I D</span>
                  List
                </label>
              </div>
              <div class="small-10 columns">
                <textarea
                  id="cc-page-user-provision-uid-list"
                  class="cc-page-user-provision-uid-list-input"
                  rows="4"
                  name="uids"
                  :value="rawUids"
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
              </div>
            </div>
            <div class="row">
              <div class="small-2 small-offset-2 columns">
                <button type="submit" class="bc-canvas-button bc-canvas-button-primary" data-ng-disabled="importButtonDisabled()">Import Users</button>
              </div>
              <div v-if="displayImportResult" class="small-8 columns">
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
              </div>
            </div>
          </b-col>
        </form>
      </b-row>
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
    rawUids: [],
    status: null,
    validationErrors: {}
  }),
}
</script>

<style scoped>
.cc-page-user-provision {
  color: #333;
  font-family: "Lato","Helvetica Neue",Helvetica,Arial,sans-serif;
  font-size: 14px;
  font-weight: 300;
  padding: 10px 20px;
}
</style>