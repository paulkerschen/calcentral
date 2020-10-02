<template>
  <div class="bc-template-sections-table-container">
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
          <td v-if="mode === 'createCourseForm'" class="bc-template-sections-table-cell-checkbox pl-2">
            <b-form-checkbox
              :id="`cc-template-canvas-manage-sections-checkbox-${section.ccn}`"
              v-model="section.selected"
              :aria-label="`Checkbox for ${section.courseCode} ${section.section_label}`"
              :aria-checked="section.selected"
              size="sm"
              @change="updateSelected"
            />
          </td>
          <td class="bc-template-sections-table-cell-course-code">
            {{ section.courseCode }}
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
              <i class="fa fa-info-circle bc-template-sections-table-sited-icon"></i>
              The section name in bCourses no longer matches the Student Information System. Use the "Update" button to rename your bCourses section name to match SIS.
            </div>
          </td>
        </tr>
        <tr
          v-if="(mode !== 'preview' && mode !== 'currentStaging' && section.sites)"
          :class="rowClassLogic({mode: mode, section: section})"
        >
          <td colspan="7" class="bc-template-sections-table-sites-cell">
            <div v-for="site in section.sites" :key="site.name" class="bc-template-sections-table-sites-container">
              <i class="fa fa-info-circle bc-template-sections-table-sited-icon"></i>
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
  methods: {
    noCurrentSections() {
      if (this.sections.length < 1) {
        return true
      }
      return !this.sections.some(section => {
        return (section.isCourseSection && section.stagedState !== 'delete') || (!section.isCourseSection && section.stagedState === 'add')
      })
    }
  }
}
</script>

<style scoped>

</style>
