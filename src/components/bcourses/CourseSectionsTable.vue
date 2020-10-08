<template>
  <div class="bc-template-sections-table-container">
    <b-form-group>
      <template v-if="sections.length > 1" #label>
        <div class="d-flex pl-2">
          <b-form-checkbox
            :id="`select-all-toggle-${sections[0].ccn}`"
            v-model="allSelected"
            :aria-label="`${allSelected ? 'Un-select' : 'Select'} all course sections`"
            class="my-2"
            :indeterminate="indeterminate"
            @change="toggleAll"
          >
            <div class="text-secondary">
              Select {{ allSelected ? 'None' : 'All' }}
            </div>
          </b-form-checkbox>
        </div>
      </template>
      <table class="bc-template-sections-table bg-white">
        <thead class="cc-visuallyhidden">
          <tr>
            <th v-if="mode === 'createCourseForm'">Action</th>
            <th>Course Code</th>
            <th>Section Label</th>
            <th>Course Control Number</th>
            <th>Schedule</th>
            <th>Location</th>
            <th>Instructors</th>
            <th v-if="mode !== 'createCourseForm' && mode !== 'preview'">
              <span v-if="mode !== 'preview'">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody v-for="section in $_.filter(sections, s => rowDisplayLogic({mode: mode, section: s}))" :key="section.ccn">
          <tr :class="rowClassLogic({mode: mode, section: section})">
            <td v-if="mode === 'createCourseForm'" class="align-top bc-template-sections-table-cell-checkbox pl-2">
              <b-form-checkbox
                :id="`cc-template-canvas-manage-sections-checkbox-${section.ccn}`"
                v-model="selected"
                :aria-checked="section.selected"
                :aria-label="`Checkbox for ${section.courseCode} ${section.section_label}`"
                class="ml-2"
                name="section-ccn"
                size="sm"
                :value="section"
              />
            </td>
            <td class="bc-template-sections-table-cell-course-code">
              <div class="pb-2 pt-1">
                {{ section.courseCode }}
              </div>
            </td>
            <td class="bc-template-sections-table-cell-section-label">
              <label
                v-if="mode === 'createCourseForm'"
                class="bc-template-sections-table-cell-section-label-label"
                for="`cc-template-canvas-manage-sections-checkbox-${section.ccn}`"
              >
                {{ section.section_label }}
              </label>
              <span v-if="mode !== 'createCourseForm'">{{ section.section_label }}</span>
            </td>
            <td class="bc-template-sections-table-cell-section-ccn">{{ section.ccn }}</td>
            <td class="bc-template-sections-table-cell-section-timestamps show-for-medium-up">
              <div v-for="(schedule, index) in section.schedules.recurring" :key="index">{{ schedule.schedule }}</div>
            </td>
            <td class="bc-template-sections-table-cell-section-locations show-for-medium-up">
              <div v-for="(schedule, index) in section.schedules.recurring" :key="index">{{ schedule.buildingName }} {{ schedule.roomNumber }}</div>
            </td>
            <td class="bc-template-sections-table-cell-section-instructors show-for-large-up">
              <div v-for="instructor in section.instructors" :key="instructor.uid">{{ instructor.name }}</div>
            </td>
            <td v-if="mode !== 'createCourseForm' && mode !== 'preview'" class="bc-template-sections-table-cell-section-action-option">
              <!-- Current Staging Actions -->
              <div v-if="mode === 'currentStaging' && section.isCourseSection">
                <button
                  v-if="section.nameDiscrepancy && section.stagedState !== 'update'"
                  :aria-label="`Include '${section.courseCode} ${section.section_label}' in the list of sections to be updated`"
                  class="bc-canvas-button bc-template-sections-table-button bc-canvas-no-decoration"
                  @click="stageUpdateAction({section: section})"
                >
                  Update
                </button>
                <button
                  v-if="section.stagedState === 'update'"
                  :aria-label="`Remove '${section.courseCode} ${section.section_label}' from list of sections to be updated from course site`"
                  class="bc-canvas-button bc-template-sections-table-button bc-template-sections-table-button-undo-delete bc-canvas-no-decoration"
                  @click="unstageAction({section: section})"
                >
                  Undo Update
                </button>
                <button
                  v-if="section.stagedState !== 'update'"
                  :aria-label="`Include '${section.courseCode} ${section.section_label}' in the list of sections to be deleted from course site`"
                  class="bc-canvas-button bc-template-sections-table-button bc-canvas-no-decoration"
                  @click="stageDeleteAction({section: section})"
                >
                  Delete
                </button>
              </div>

              <div v-if="mode === 'currentStaging' && !section.isCourseSection">
                <button
                  class="bc-canvas-button bc-template-sections-table-button bc-template-sections-table-button-undo-add bc-canvas-no-decoration"
                  :aria-label="`Remove '${section.courseCode} ${section.section_label}' from list of sections to be added to course site`"
                  @click="unstageAction({section: section})"
                >
                  Undo Add
                </button>
              </div>

              <!-- Available Staging Actions -->
              <div v-if="mode === 'availableStaging' && section.isCourseSection && section.stagedState === 'delete'">
                <button
                  class="bc-canvas-button bc-template-sections-table-button bc-template-sections-table-button-undo-delete bc-canvas-no-decoration"
                  :aria-label="`Remove '${section.courseCode} ${section.section_label}' from list of sections to be deleted from course site`"
                  @click="unstageAction({section: section})"
                >
                  Undo Delete
                </button>
              </div>

              <div v-if="mode === 'availableStaging' && !section.isCourseSection && section.stagedState === 'add'">
                Added <span class="cc-visuallyhidden">to pending list of new sections</span>
              </div>

              <div v-if="mode === 'availableStaging' && !section.isCourseSection && section.stagedState === null">
                <button
                  class="bc-canvas-button bc-canvas-button-primary bc-template-sections-table-button bc-canvas-no-decoration"
                  :class="{'bc-template-sections-table-button-undo-add': section.stagedState === 'add'}"
                  :aria-label="`Include '${section.courseCode} ${section.section_label}' in the list of sections to be added to course site`"
                  @click="stageAddAction({section: section})"
                >
                  Add
                </button>
              </div>
            </td>
          </tr>
          <tr
            v-if="mode === 'currentStaging' && section.nameDiscrepancy && section.stagedState !== 'update'"
            :class="rowClassLogic({mode: mode, section: section})"
          >
            <td colspan="7" class="bc-template-sections-table-sites-cell">
              <div class="bc-template-sections-table-sites-container">
                <fa icon="info-circle" class="bc-template-sections-table-sited-icon mr-1"></fa>
                The section name in bCourses no longer matches the Student Information System.
                Use the "Update" button to rename your bCourses section name to match SIS.
              </div>
            </td>
          </tr>
          <tr
            v-if="(mode !== 'preview' && mode !== 'currentStaging' && section.sites)"
            :class="rowClassLogic({mode: mode, section: section})"
          >
            <td colspan="7" class="bc-template-sections-table-sites-cell">
              <div v-for="site in section.sites" :key="site.name" class="bc-template-sections-table-sites-container ml-4 pl-3">
                <fa icon="info-circle" class="bc-template-sections-table-sited-icon mr-1" size="sm"></fa>
                This section is already in use by <a :href="site.site_url">{{ site.name }}</a>
              </div>
            </td>
          </tr>
        </tbody>
        <tbody v-if="mode === 'preview' && sections.length < 1">
          <tr>
            <td colspan="7">There are no currently maintained official sections in this course site</td>
          </tr>
        </tbody>
        <tbody v-if="mode === 'currentStaging' && noCurrentSections()">
          <tr>
            <td colspan="7">No official sections will remain in course site</td>
          </tr>
        </tbody>
      </table>
    </b-form-group>
  </div>
</template>

<script>
export default {
  name: 'CourseSectionsTable',
  props: {
    mode: {
      required: true,
      type: String
    },
    rowClassLogic: {
      default: () => '',
      required: false,
      type: Function
    },
    rowDisplayLogic: {
      default: () => true,
      required: false,
      type: Function
    },
    sections: {
      required: true,
      type: Array
    },
    stageDeleteAction: {
      default: () => {},
      required: false,
      type: Function
    },
    stageAddAction: {
      default: () => {},
      required: false,
      type: Function
    },
    stageUpdateAction: {
      default: () => {},
      required: false,
      type: Function
    },
    unstageAction: {
      default: () => {},
      required: false,
      type: Function
    },
    updateSelected: {
      required: true,
      type: Function
    }
  },
  watch: {
    selected(objects) {
      if (!objects.length) {
        this.allSelected = false
        this.indeterminate = false
      } else if (objects.length === this.sections.length) {
        this.allSelected = true
        this.indeterminate = false
      } else {
        this.allSelected = false
        this.indeterminate = true
      }
      this.updateSelected()
    }
  },
  data: () => ({
    selected: [],
    allSelected: false,
    indeterminate: false
  }),
  methods: {
    noCurrentSections() {
      if (this.sections.length < 1) {
        return true
      }
      return !this.sections.some(section => {
        return (section.isCourseSection && section.stagedState !== 'delete') || (!section.isCourseSection && section.stagedState === 'add')
      })
    },
    toggleAll(checked) {
      this.selected = checked ? this.sections.slice() : []
    }
  }
}
</script>

<style scoped lang="scss">
td {
  padding-top: 5px;
}
.bc-template-sections-table-cell-checkbox {
  width: 30px;
}
.bc-template-sections-table-row-disabled td {
  color: $bc-color-grey-disabled;
}
.bc-template-sections-table-row-added td {
  background-color: $bc-color-yellow-row-highlighted;
}
.bc-template-sections-table-row-deleted td {
  background-color: $bc-color-red-row-highlighted;
}
.bc-template-sections-table-cell-section-action-option {
  height: 45px;
  text-align: right;
}
.bc-template-sections-table-button {
  font-size: 12px;
  margin: 0;
  padding: 2px 8px;
  white-space: nowrap;
}
.bc-template-sections-table-button-undo-add {
  background-color: $bc-color-orange-button-bg;
  border: $bc-color-orange-button-border solid 1px;
  color: $bc-color-white;
  &:hover, &:active, &:focus, &:link {
    background: $bc-color-orange-button-bg-selected;
    border-color: $bc-color-orange-button-border-selected;
  }
}
.bc-template-sections-table-button-undo-delete {
  background-color: $bc-color-red-button-bg;
  border: $bc-color-red-button-border solid 1px;
  color: $bc-color-white;
  &:hover, &:active, &:focus, &:link {
    background: $bc-color-red-button-bg-selected;
    border-color: $bc-color-red-button-border-selected;
  }
}
.bc-template-sections-table-cell-course-code {
  font-size: 13px;
  width: 115px;
}
.bc-template-sections-table-cell-section-ccn {
  width: 70px;
}
.bc-template-sections-table-cell-section-timestamps {
  width: 155px;
}
.bc-template-sections-table-cell-section-locations {
  width: 150px;
}
.bc-template-sections-table-cell-section-instructors {
  width: 183px;
}
.bc-template-sections-table-cell-section-label {
  padding-top: 7px;
}
.bc-template-sections-table-cell-section-label-label {
  cursor: pointer;
  font-size: 13px;
  margin: 0;
  text-align: left;
}
.bc-template-sections-table-sited-icon {
  color: $bc-color-help-link-blue;
}
.bc-template-sections-table-sites-cell {
  padding: 0 14px;
}
.bc-template-sections-table-sites-container {
  margin-bottom: 5px;
}
</style>
