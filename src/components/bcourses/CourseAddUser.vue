<template>
  <div class="bc-canvas-application bc-page-course-add-user">
    <MaintenanceNotice course-action-verb="user is added" />

    <h1 class="bc-page-course-add-user-header">Find a Person to Add</h1>

    <div v-if="showError">
      <fa icon="exclamation-triangle" class="cc-icon-red bc-canvas-notice-icon"></fa>
      {{ errorStatus }}
    </div>

    <div v-if="!showError">
      <b-row v-if="showAlerts" role="alert">
        <b-col v-if="isLoading" md="12" class="cc-spinner"></b-col>
        <b-col v-if="!isLoading" md="12">
          <div v-if="noUserSelectedAlert" class="bc-alert bc-alert-error bc-page-course-add-user-alert">
            Please select a user.
            <div class="bc-alert-close-button-container">
              <button
                id="hide-select-user-alert-button"
                class="bc-close-button"
                @click="noUserSelectedAlert = ''"
              >
                <fa icon="times-circle"></fa>
                <span class="cc-visuallyhidden">Hide Alert</span>
              </button>
            </div>
          </div>

          <div v-if="noSearchResultsNotice" class="bc-alert bc-alert-error bc-page-course-add-user-alert">
            Your search did not match any users with a CalNet ID.
            {{ searchTypeNotice }}
            Please try again.
            <div class="bc-alert-close-button-container">
              <button
                id="hide-search-alert-button"
                class="bc-close-button"
                @click="noSearchResultsNotice = ''"
              >
                <fa icon="times-circle"></fa>
                <span class="cc-visuallyhidden">Hide Alert</span>
              </button>
            </div>
          </div>

          <div v-if="userSearchResultsCount > userSearchResults.length" class="bc-alert bc-alert-info bc-page-course-add-user-alert">
            Your search returned {{ userSearchResultsCount }} results, but only the first
            {{ userSearchResults.length }} are shown.
            Please refine your search to limit the number of results.
          </div>

          <div v-if="userSearchResultsCount === userSearchResults.length" class="cc-visuallyhidden">
            {{ userSearchResultsCount }} user search results loaded.
          </div>

          <div v-if="additionSuccessMessage" id="success-message" class="bc-alert bc-alert-success bc-page-course-add-user-alert">
            {{ userAdded.fullName }} was added to the
            &ldquo;{{ userAdded.sectionName }}&rdquo; section of this course as a {{ userAdded.role }}.
            <div class="bc-alert-close-button-container">
              <button class="bc-close-button" @click="additionSuccessMessage = ''">
                <fa icon="times-circle"></fa>
                <span class="cc-visuallyhidden">Hide Alert</span>
              </button>
            </div>
          </div>

          <div v-if="additionFailureMessage" class="bc-alert bc-alert-error bc-page-course-add-user-alert">
            <fa icon="exclamation-triangle" class="cc-icon-red bc-canvas-notice-icon"></fa>
            {{ errorStatus }}
            <div class="bc-alert-close-button-container">
              <button class="bc-close-button" @click="additionFailureMessage = ''">
                <fa icon="times-circle"></fa>
                <span class="cc-visuallyhidden">Hide Alert</span>
              </button>
            </div>
          </div>
        </b-col>
      </b-row>

      <b-row v-if="showSearchForm" no-gutters>
        <b-col md="6">
          <form class="bc-canvas-page-form" @submit.prevent="searchUsers">
            <b-row class="bc-horizontal-form" no-gutters>
              <b-col md="4">
                <label for="search-text" class="cc-visuallyhidden">Search users</label>
                <input
                  id="search-text"
                  v-model="searchText"
                  class="bc-form-input-text"
                  :type="searchTextType"
                  placeholder="Find a person to add"
                >
              </b-col>
              <b-col md="6">
                <b-row no-gutters>
                  <b-col md="2">
                    <label for="search-type" class="bc-label bc-label-horizontal bc-form-entities">By:</label>
                  </b-col>
                  <b-col md="10">
                    <select
                      id="search-type"
                      v-model="searchType"
                      class="bc-form-input-select"
                      @change="updateSearchTextType"
                    >
                      <option value="name">Last Name, First Name</option>
                      <option value="email">Email</option>
                      <option value="ldap_user_id" aria-label="CalNet U I D">CalNet UID</option>
                    </select>
                  </b-col>
                </b-row>
              </b-col>
              <b-col md="2" class="bc-column-align-center">
                <button
                  id="submit-search"
                  type="submit"
                  class="bc-canvas-button bc-canvas-button-primary bc-full-wide"
                  aria-label="Perform User Search"
                >
                  Go
                </button>
              </b-col>
            </b-row>
          </form>
        </b-col>
      </b-row>

      <b-row v-if="showSearchForm" class="bc-page-help-notice" no-gutters>
        <b-col md="12">
          <fa icon="question-circle" class="bc-page-help-notice-icon cc-left mr-2"></fa>
          <div class="bc-page-help-notice-left-margin">
            <button
              class="bc-button-link"
              aria-controls="bc-page-help-notice"
              aria-haspopup="true"
              :aria-expanded="toggle.displayHelp"
              @click="toggle.displayHelp = !toggle.displayHelp"
            >
              Need help finding someone?
            </button>
            <div aria-live="polite">
              <div v-if="toggle.displayHelp" id="bc-page-help-notice" class="bc-page-help-notice-content bc-user-search-notice">
                <!-- Note: This help text content is also maintained in the public/canvas/canvas-customization.js script -->
                <dl class="bc-user-search-notice-description-list">
                  <dt class="bc-user-search-notice-description-term">UC Berkeley Faculty, Staff and Students</dt>
                  <dd class="bc-user-search-notice-description">
                    UC Berkeley faculty, staff and students <em>(regular and concurrent enrollment)</em> can be found in the
                    <OutboundLink href="http://directory.berkeley.edu/">CalNet Directory</OutboundLink>
                    and be added to your site using their CalNet UID or official email address.
                  </dd>
                  <dt class="bc-user-search-notice-description-term">Guests</dt>
                  <dd class="bc-user-search-notice-description">
                    Peers from other institutions or guests from the community must be sponsored with a
                    <OutboundLink href="https://idc.berkeley.edu/guests/">CalNet Guest Account</OutboundLink>.
                    Do NOT request a CalNet Guest Account for concurrent enrollment students.
                  </dd>
                  <dt class="bc-user-search-notice-description-term">More Information</dt>
                  <dd class="bc-user-search-notice-description">
                    Go to this
                    <OutboundLink href="https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0010842">bCourses help page</OutboundLink>
                    for more information about adding people to bCourse sites.
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </b-col>
      </b-row>

      <b-row v-if="showUsersArea" no-gutters>
        <b-col v-if="isLoading" md="12" class="cc-spinner"></b-col>
        <h2 class="cc-visuallyhidden" data-cc-focus-reset-directive="searchResultsFocus">User Search Results</h2>
        <b-col v-if="userSearchResults.length > 0" md="12">
          <form class="bc-canvas-page-form">
            <fieldset class="bc-form-fieldset">
              <legend class="cc-visuallyhidden">Select the user you wish to add to the course site:</legend>
              <table class="bc-table bc-table-striped">
                <thead>
                  <tr>
                    <th scope="col"><span class="cc-visuallyhidden">Actions</span></th>
                    <th scope="col">Name</th>
                    <th scope="col">Calnet UID</th>
                    <th scope="col">Email</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(user, index) in userSearchResults" :key="user.ldapUid">
                    <td>
                      <input
                        :id="`bc-user-search-result-${index}`"
                        v-model="selectedUser"
                        type="radio"
                        name="selectedUser"
                        :value="user"
                        :aria-labelled-by="`bc-user-search-result-${index} bc-user-search-result-ldap-uid-${index}`"
                      >
                    </td>
                    <td>
                      <label :for="`bc-user-search-result-${index}`" class="bc-form-input-label-no-align">
                        {{ user.firstName }} {{ user.lastName }}
                      </label>
                    </td>
                    <td>
                      <span :id="`bc-user-search-result-ldap-uid-${index}`">
                        {{ user.ldapUid }}
                      </span>
                    </td>
                    <td>{{ user.emailAddress }}</td>
                  </tr>
                </tbody>
              </table>
            </fieldset>
            <b-row no-gutters>
              <b-col md="7">
                <b-row no-gutters>
                  <b-col sm="3">
                    <label for="user-role"><strong><span class="cc-required-field-indicator">*</span> Role</strong>:</label>
                  </b-col>
                  <b-col sm="9">
                    <select id="user-role" v-model="selectedRole" class="bc-form-input-select">
                      <option v-for="role in grantingRoles" :key="role" :value="role">
                        {{ role }}
                      </option>
                    </select>
                  </b-col>
                </b-row>
                <b-row no-gutters>
                  <b-col sm="3">
                    <label for="course-section"><strong><span class="cc-required-field-indicator">*</span> Section</strong>:</label>
                  </b-col>
                  <b-col sm="9">
                    <select id="course-section" v-model="selectedSection" class="bc-form-input-select">
                      <option v-for="section in courseSections" :key="section.name" :value="section">
                        {{ section.name }}
                      </option>
                    </select>
                  </b-col>
                </b-row>
              </b-col>
            </b-row>
            <b-row no-gutters>
              <b-col md="12" class="bc-form-actions">
                <button
                  type="button"
                  class="bc-canvas-button bc-start-over-button"
                  @click="resetForm"
                >
                  Start Over
                </button>
                <button
                  :disabled="!selectedUser"
                  type="button"
                  class="bc-canvas-button bc-canvas-button-primary"
                  @click="submitUser"
                >
                  Add User
                </button>
              </b-col>
            </b-row>
          </form>
        </b-col>
      </b-row>
    </div>
  </div>
</template>

<script>
import CanvasUtils from '@/mixins/CanvasUtils'
import Context from '@/mixins/Context'
import Iframe from '@/mixins/Iframe'
import MaintenanceNotice from '@/components/bcourses/shared/MaintenanceNotice'
import OutboundLink from '@/components/util/OutboundLink'
import {addUser, getAddUserCourseSections, getCourseUserRoles, searchUsers} from '@/api/canvas'

export default {
  name: 'CourseAddUser',
  components: {MaintenanceNotice, OutboundLink},
  mixins: [CanvasUtils, Context, Iframe],
  data: () => ({
    additionFailureMessage: null,
    additionSuccessMessage: null,
    canvasCourseId: null,
    courseSections: [],
    errorStatus: null,
    grantingRoles: [],
    isLoading: null,
    noSearchResultsNotice: null,
    noUserSelectedAlert: null,
    searchText: null,
    searchTextType: 'text',
    searchType: 'name',
    searchTypeNotice: null,
    selectedRole: null,
    selectedSection: null,
    selectedUser: null,
    showAlerts: null,
    showError: null,
    showSearchForm: null,
    showUsersArea: null,
    toggle: {
      displayHelp: false
    },
    userAdded: {},
    userSearchResultsCount: 0,
    userSearchResults: []
  }),
  methods: {
    isAuthorized(response) {
      return (
        this.$_.includes(response.roleTypes, 'TeacherEnrollment') ||
        this.$_.includes(response.roleTypes, 'TaEnrollment') ||
        this.$_.includes(response.roles, 'globalAdmin')
      )
    },
    resetForm() {
      this.searchTextType = 'text'
      this.searchText = ''
      this.searchType = 'name'
      this.searchTypeNotice = ''
      this.showAlerts = false
      this.resetSearchState()
      this.resetImportState()
    },
    resetImportState() {
      this.userAdded = false
      this.showAlerts = false
      this.additionSuccessMessage = false
      this.additionFailureMessage = false
    },
    resetSearchState() {
      this.noSearchResultsNotice = false
      this.noUserSelectedAlert = false
      this.selectedUser = null
      this.showUsersArea = false
      this.userSearchResults = []
      this.userSearchResultsCount = 0
    },
    searchUsers() {
      this.resetSearchState()
      this.resetImportState()
      this.alertScreenReader('Loading user search results')
      this.showUsersArea = true
      this.isLoading = true
      searchUsers(this.canvasCourseId, this.searchText, this.searchType).then(response => {
        this.userSearchResults = response.users
        if (response.users && response.users.length) {
          this.userSearchResultsCount = response.users[0].resultCount
          this.selectedUser = response.users[0]
        } else {
          this.setSearchTypeNotice()
          this.userSearchResultsCount = 0
          this.noSearchResultsNotice = true
        }
        this.isLoading = false
        this.showAlerts = true
        this.searchResultsFocus = true
      }, () => {
        this.showError = true
        this.errorStatus = 'User search failed.'
        this.isLoading = false
        this.showAlerts = true
      })
    },
    setSearchTypeNotice() {
      this.searchTypeNotice = (this.searchType === 'ldap_user_id') ? 'CalNet UIDs must be an exact match.' : ''
    },
    showUnauthorized() {
      this.isLoading = false
      this.showError = true
      this.errorStatus = 'Authorization check failed.'
    },
    submitUser() {
      this.iframeScrollToTop()
      this.showUsersArea = false
      this.showSearchForm = false
      this.alertScreenReader('Adding user')
      this.isLoading = true
      this.showAlerts = true
      addUser(this.canvasCourseId, this.selectedUser.ldapUid, this.selectedSection.id, this.selectedRole).then(response => {
        this.userAdded = {
          ...response.userAdded,
          fullName: this.selectedUser.firstName + ' ' + this.selectedUser.lastName,
          role: this.selectedRole,
          sectionName: this.selectedSection.name
        }
        this.additionSuccessMessage = true
        this.showSearchForm = true
        this.isLoading = false
        this.resetSearchState()
      }, () => {
        this.errorStatus = 'Request to add user failed'
        this.showSearchForm = true
        this.additionFailureMessage = true
        this.isLoading = false
        this.resetSearchState()
      })
    },
    updateSearchTextType() {
      this.searchTextType = (this.searchType === 'ldap_user_uid') ? 'number' : 'text'
    }
  },
  created() {
    this.isLoading = true
    this.getCanvasCourseId()
    getCourseUserRoles(this.canvasCourseId).then(response => {
      if (this.isAuthorized(response)) {
        this.grantingRoles = response.grantingRoles
        this.selectedRole = response.grantingRoles[0]
        getAddUserCourseSections(this.canvasCourseId).then(response => {
          this.isLoading = false
          this.courseSections = response.courseSections
          this.selectedSection = response.courseSections[0]
          this.showSearchForm = true
        }, this.showUnauthorized)
      } else {
        this.showUnauthorized()
      }
    }, this.showUnauthorized)
  }
}
</script>

<style scoped lang="scss">
.bc-page-course-add-user {
  background: $cc-color-white;
  padding: 10px;

  .bc-page-course-add-user-alert {
    margin-bottom: 20px;
  }

  .bc-page-course-add-user-header {
    color: $bc-color-off-black;
    font-family: $bc-base-font-family;
    font-size: 23px;
    font-weight: 400;
    line-height: 40px;
    margin: 8px 0;
  }

  button {
    &, &:hover, &:active, &:focus {
      font-family: $bc-base-font-family;
      font-size: 14px;
      font-weight: 300;
    }
  }

  p {
    font-size: 14px;
    line-height: 16px;
    margin: 0 0 10px;
  }

  select {
    width: 100%;
  }

  .bc-canvas-page-form {
    form input[type="text"] {
      font-family: $bc-base-font-family;
      font-size: 14px;
      margin: 2px 10px 0 0;
      padding: 8px 12px;
    }

    .bc-form-input-select {
      margin-bottom: 8px;
    }
  }

  .bc-horizontal-form {
    .bc-label {
      white-space: nowrap;
    }

    .bc-label-horizontal {
      margin-top: 9px;
    }

    .bc-form-entity {
      border: 1px solid $cc-color-very-light-grey;
      font-family: Arial;
      font-size: 12px;
      height: 25px;
      margin: 3px 0;
      padding: 5px;
    }
  }

  .bc-fa-black {
    color: $bc-color-off-black !important;
  }

  .bc-user-search-notice {
    .bc-user-search-notice-description-list {
      margin-bottom: 0;
    }
    .bc-user-search-notice-description-term {
      font-weight: bold;
      margin: 5px 0;
    }
    .bc-user-search-notice-description {
      margin-left: 15px;
    }
  }

  .bc-column-align-center {
    text-align: center;
  }

  @media #{$small-only} {
    .bc-full-wide {
      width: 100%;
    }

    .bc-horizontal-form {
      .columns {
        margin-bottom: 0;
      }
    }
  }
}
</style>
