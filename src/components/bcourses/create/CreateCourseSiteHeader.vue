<template>
  <div class="bc-page-create-course-site-admin-options">
    <h2 class="cc-visuallyhidden">Administrator Options</h2>
    <b-button
      id="toggle-admin-mode-button"
      aria-controls="bc-page-create-course-site-admin-section-loader-form"
      class="bc-canvas-button bc-canvas-button-small bc-page-create-course-site-admin-mode-switch pb-2 ptl-3 pr-2 pt-2"
      @click="setMode(adminMode === 'act_as' ? 'by_ccn' : 'act_as')"
    >
      Switch to {{ adminMode === 'act_as' ? 'CCN input' : 'acting as instructor' }}
    </b-button>
    <div id="bc-page-create-course-site-admin-section-loader-form">
      <div v-if="adminMode === 'act_as'" class="pt-3">
        <h3 class="cc-visuallyhidden">Load Sections By Instructor UID</h3>
        <form class="bc-canvas-page-form bc-page-create-course-site-act-as-form d-flex" @submit.prevent="submit">
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
              :disabled="!uid"
              aria-label="Load official sections for instructor"
              aria-controls="bc-page-create-course-site-steps-container"
              @click="submit"
            >
              As instructor
            </b-button>
          </div>
        </form>
      </div>
      <div v-if="adminMode === 'by_ccn'">
        <h3 id="load-sections-by-ccn" class="cc-visuallyhidden">Load Sections By Course Control Numbers (CCN)</h3>
        <form class="bc-canvas-page-form" @submit.prevent="submit">
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
            ></textarea>
            <b-button
              id="sections-by-ids-button"
              class="bc-canvas-button bc-canvas-button-primary"
              aria-controls="bc-page-create-course-site-steps-container"
              :disabled="!$_.trim(ccns)"
              type="submit"
              @click="submit"
            >
              Review matching CCNs
            </b-button>
          </div>
        </form>
      </div>
      <div
        v-if="error"
        aria-live="polite"
        class="has-error pl-2 pt-2"
        role="alert"
      >
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Utils from '@/mixins/Utils'

export default {
  name: 'CreateCourseSiteHeader',
  mixins: [Context, Utils],
  watch: {
    ccns() {
      this.error = null
    },
    uid() {
      this.error = null
    }
  },
  props: {
    adminMode: {
      required: true,
      type: String
    },
    adminSemesters: {
      default: undefined,
      required: false,
      type: Array
    },
    currentAdminSemester: {
      required: true,
      type: String
    },
    fetchFeed: {
      required: true,
      type: Function
    },
    setAdminActingAs: {
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
    ccns: '',
    error: undefined,
    uid: undefined
  }),
  methods: {
    setMode(mode) {
      this.setAdminMode(mode)
      if (mode === 'by_ccn') {
        this.alertScreenReader('Input mode switched to section ID')
        this.$putFocusNextTick('load-sections-by-ccn')
      } else {
        this.alertScreenReader(`Input mode switched to ${mode === 'by_ccn' ? 'section ID' : 'UID'}`)
        this.$putFocusNextTick(mode === 'by_ccn' ? 'load-sections-by-ccn' : 'instructor-uid')
      }
    },
    submit() {
      if (this.adminMode === 'by_ccn') {
        const trimmed = this.$_.trim(this.ccns)
        const split = this.$_.split(trimmed, /[,\r\n\t ]+/)
        const notNumeric = this.$_.partition(split, ccn => /^\d+$/.test(this.$_.trim(ccn)))[1]
        if (notNumeric.length) {
          this.error = 'CCNs must be numeric.'
          this.$putFocusNextTick('bc-page-create-course-site-ccn-list')
        } else {
          this.setAdminByCcns(split)
          this.fetchFeed()
        }
      } else {
        const trimmed = this.$_.trim(this.uid)
        if (/^\d+$/.test(trimmed)) {
          this.setAdminActingAs(trimmed)
          this.fetchFeed()
        } else {
          this.error = 'UID must be numeric.'
          this.$putFocusNextTick('instructor-uid')
        }
      }
    }
  }
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
.bc-page-create-course-site-admin-mode-switch {
  margin-bottom: 5px;
  outline: none;
}
.bc-page-create-course-site-header {
  color: $bc-color-headers;
  font-family: $bc-base-font-family;
  font-weight: normal;
  line-height: 40px;
  margin: 5px 0;
}
.has-error {
  color: $bc-color-alert-error-foreground;
  font-size: 14px;
  font-weight: bolder;
}
</style>
