<template>
  <div class="d-flex flex-column">
    <div class="order-3">
      <h1 class="bc-page-create-course-site-header bc-page-create-course-site-header1">Create a Course Site</h1>
    </div>
    <div class="order-2">
      <div v-if="showMaintenanceNotice" role="alert">
        <MaintenanceNotice />
      </div>
    </div>
    <div class="order-1">
      <div>
        <div v-if="isAdmin" class="bc-page-create-course-site-admin-options">
          <h1 class="cc-visuallyhidden">Administrator Options</h1>
          <button
            aria-controls="bc-page-create-course-site-admin-section-loader-form"
            class="bc-canvas-button bc-canvas-button-small bc-page-create-course-site-admin-mode-switch p-2"
            @click="setAdminMode(adminMode === 'act_as' ? 'by_ccn' : 'act_as')"
          >
            Switch to {{ adminMode === 'act_as' ? 'CCN input' : 'acting as instructor' }}
          </button>
          <div id="bc-page-create-course-site-admin-section-loader-form">
            <div v-if="adminMode === 'act_as'" class="pt-3">
              <h2 class="cc-visuallyhidden">Load Sections By Instructor UID</h2>
              <form class="bc-canvas-page-form bc-page-create-course-site-act-as-form d-flex" @submit="fetchFeed">
                <label for="instructor-uid" class="cc-visuallyhidden">Instructor UID</label>
                <b-form-input
                  id="instructor-uid"
                  v-model="uid"
                  placeholder="Instructor UID"
                  role="search"
                ></b-form-input>
                <div>
                  <b-button
                    id="sections-by-uid-button"
                    class="bc-canvas-button bc-canvas-button-primary"
                    :disabled="!toInt(uid)"
                    aria-label="Load official sections for instructor"
                    aria-controls="bc-page-create-course-site-steps-container"
                    @click="fetchFeed"
                  >
                    As instructor
                  </b-button>
                </div>
              </form>
            </div>
            <div v-if="adminMode === 'by_ccn'">
              <h2 class="cc-visuallyhidden">Load Sections By Course Control Numbers (CCN)</h2>
              <form class="bc-canvas-page-form" @submit="fetchFeed">
                <div v-if="$_.size(adminSemesters)">
                  <div class="bc-buttonset">
                    <span v-for="(semester, index) in adminSemesters" :key="index">
                      <input
                        :id="`semester${index}`"
                        type="radio"
                        name="adminSemester"
                        class="cc-visuallyhidden"
                        :aria-selected="currentAdminSemester === semester.slug"
                        role="tab"
                        @click="switchAdminSemester(semester)"
                      />
                      <label
                        :for="`semester${index}`"
                        class="bc-buttonset-button"
                        role="button"
                        aria-disabled="false"
                        :class="{
                          'bc-buttonset-button-active': currentAdminSemester === semester.slug,
                          'bc-buttonset-corner-left': index === 0,
                          'bc-buttonset-corner-right': index === ($_.size(adminSemesters) - 1)
                        }"
                      >
                        {{ semester.name }}
                      </label>
                    </span>
                  </div>
                  <label
                    for="bc-page-create-course-site-ccn-list"
                    class="cc-visuallyhidden"
                  >
                    Provide CCN List Separated by Commas or Spaces
                  </label>
                  <textarea
                    id="bc-page-create-course-site-ccn-list"
                    v-model="ccns"
                    placeholder="Paste your list of CCNs here, separated by commas or spaces"
                  >
                </textarea>
                  <b-button
                    id="sections-by-ids-button"
                    class="bc-canvas-button bc-canvas-button-primary"
                    :disabled="!$_.trim(ccns)"
                    type="submit"
                    aria-controls="bc-page-create-course-site-steps-container"
                  >
                    Review matching CCNs
                  </b-button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import MaintenanceNotice from '@/components/bcourses/shared/MaintenanceNotice'
import Utils from '@/mixins/Utils'

export default {
  name: 'CreateCourseSiteHeader',
  mixins: [Utils],
  components: {MaintenanceNotice},
  watch: {
    ccns(value) {
      this.setAdminByCcns(value)
    },
    uid() {
      this.setAdminActingAs(this.uid)
    }
  },
  props: {
    setAdminActingAs: {
      required: true,
      type: Function
    },
    adminMode: {
      required: true,
      type: String
    },
    adminSemesters: {
      required: true,
      type: Array
    },
    currentAdminSemester: {
      default: undefined,
      required: false,
      type: String
    },
    isAdmin: {
      required: true,
      type: Boolean
    },
    fetchFeed: {
      required: true,
      type: Function
    },
    setAdminByCcns: {
      required: true,
      type: Function
    },
    setAdminMode: {
      required: true,
      type: Function
    },
    showMaintenanceNotice: {
      required: true,
      type: Boolean
    },
    switchAdminSemester: {
      required: true,
      type: Function
    }
  },
  data: () => ({
    ccns: [],
    uid: undefined
  })
}
</script>

<style scoped lang="scss">
.bc-page-create-course-site-act-as-form {
  margin: 5px 0;
  input[type="text"] {
    font-family: $bc-base-font-family;
    font-size: 14px;
    margin: 2px 10px 0 0;
    padding: 8px 12px;
    width: 140px;
  }
}

.bc-page-create-course-site-admin-options {
  margin-bottom: 15px;
}

.bc-page-create-course-site-header {
  color: $bc-color-headers;
  font-family: $bc-base-font-family;
  font-weight: normal;
  line-height: 40px;
  margin: 5px 0;
}

.bc-page-create-course-site-header1 {
  font-size: 23px;
}

.bc-page-create-course-site-header2 {
  font-size: 18px;
  margin: 10px 0;
}

.bc-page-create-course-site-admin-mode-switch {
  margin-bottom: 5px;
  outline: none;
}
</style>
