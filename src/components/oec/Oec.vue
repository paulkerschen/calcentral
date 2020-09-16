<template>
  <div>
    <h2 class="cc-text-big pb-2">OEC</h2>
    <div>
      <b-form-select
        id="cc-page-oec-task"
        v-model="taskName"
        :options="tasks"
        placeholder="Choose a task"
        text-field="friendlyName"
        value-field="name"
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
          v-model="departmentSelect"
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
</template>

<script>
import Context from '@/mixins/Context'
import {getTasks, runTask} from '@/api/oec'

export default {
  name: 'Oec',
  data: () => ({
    departmentsParticipating: null,
    departmentSelect: null,
    departmentMultiSelect: [],
    taskName: null,
    term: undefined,
    departments: undefined,
    tasks: undefined,
    terms: undefined
  }),
  mixins: [Context],
  created() {
    getTasks().then(data => {
      this.departments = data.oecDepartments
      this.term = data.currentTerm
      this.terms = data.oecTerms
      this.tasks = data.oecTasks

      this.departmentsParticipating = []
      this.$_.each(this.departments, department => {
        if (department.participating) {
          this.departmentsParticipating.push(department)
        }
      })
    })
  },
  methods: {
    getTaskObject(name) {
      return name && this.$_.find(this.tasks, ['name', name])
    },
    run() {
      runTask(this.taskName, this.term, null).then(status => {
        console.log(status)
      })
    }
  }
}
</script>

<style scoped>
li {
  list-style-type: none;
}
</style>
