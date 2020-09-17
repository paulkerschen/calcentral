<template>
  <div>
    <h2 class="cc-text-big pb-2">OEC</h2>
    <div v-if="isTaskRunning">
      <RunTask
        :department-code="departmentCode"
        :done="isTaskRunning = false"
        :task="getTaskObject(taskName)"
        :term="term"
      />
    </div>
    <div v-if="!isTaskRunning">
      <div>
        <b-form-select
          id="cc-page-oec-task"
          v-model="taskName"
          :options="tasks"
          placeholder="Choose a task"
          text-field="friendlyName"
          value-field="name"
          @change="departmentCode = null"
        >
          <template v-slot:first>
            <b-form-select-option :value="null">Select task...</b-form-select-option>
          </template>
        </b-form-select>
      </div>
      <div v-if="taskName" class="pt-2">
        <b-form-select
          id="cc-page-oec-term"
          v-model="term"
          class="pb-1"
          :options="terms"
          option-label="friendlyName"
        ></b-form-select>
      </div>
      <div v-if="$_.includes(['SisImportTask', 'CreateConfirmationSheetsTask', 'ReportDiffTask'], taskName)" class="pt-2">
        <div>
          <b-form-select
            id="cc-page-oec-department"
            v-model="departmentCode"
            :options="departments"
            text-field="name"
            value-field="code"
          >
            <template v-slot:first>
              <b-form-select-option :value="null">All participating departments</b-form-select-option>
            </template>
          </b-form-select>
        </div>
        <div>
          <b-button
            id="show-participating-departments"
            v-b-toggle.participating-collapse
            class="pb-0 pt-0"
            size="sm"
            variant="link"
          >
            Show participating departments
          </b-button>
          <b-collapse id="participating-collapse" class="mt-2">
            <ul class="cc-text-small participating-list">
              <li v-for="d in departmentsParticipating" :key="d.code">{{ d.name }}</li>
            </ul>
          </b-collapse>
        </div>
      </div>
      <div v-if="taskName === 'MergeConfirmationSheetsTask'" class="pt-2">
        <b-form-select
          v-model="departmentMultiSelect"
          :options="departments"
          multiple
          :select-size="10"
          text-field="name"
          value-field="code"
        ></b-form-select>
      </div>
      <div v-if="taskName" class="p-3">
        <span id="oec-task-description" class="cc-text-small text-secondary" v-html="$_.get(this.getTaskObject(taskName), 'htmlDescription')"></span>
      </div>
      <div class="p-2">
        <b-button
          id="oec-run-task-button"
          :disabled="!taskName || !term || (taskName === 'MergeConfirmationSheetsTask' && !departmentMultiSelect.length)"
          size="sm"
          variant="primary"
          @click="run"
        >
          Run task
        </b-button>
      </div>
    </div>
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import RunTask from '@/components/oec/RunTask'
import {getTasks} from '@/api/oec'

export default {
  name: 'Oec',
  data: () => ({
    departmentCode: null,
    departmentsParticipating: undefined,
    taskName: null,
    term: undefined,
    departments: undefined,
    isTaskRunning: false,
    tasks: undefined,
    terms: undefined
  }),
  mixins: [Context],
  components: {RunTask},
  created() {
    getTasks().then(data => {
      this.departments = data.oecDepartments
      this.term = data.currentTerm
      this.terms = data.oecTerms
      this.tasks = data.oecTasks

      this.departmentCode = []
      this.$_.each(this.departments, department => {
        if (department.participating) {
          this.departmentCode.push(department)
        }
      })
    })
  },
  methods: {
    getTaskObject(name) {
      return name && this.$_.find(this.tasks, ['name', name])
    },
    run() {
      this.isTaskRunning = true
    }
  }
}
</script>

<style scoped>
li {
  list-style-type: none;
}
</style>
