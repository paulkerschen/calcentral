<template>
  <div>
    <div class="cc-widget-title">
      <h2 class="cc-text-big">OEC</h2>
    </div>
    <div class="bg-white p-3">
      <div v-if="isTaskRunning">
        <RunTask
          :key="taskName"
          :department-code="runTaskDepartmentCodes"
          :on-finish="taskRunDone"
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
            @change="resetModelObjects"
          >
            <template #first>
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
        <b-form-group
          v-if="taskRequiresDepartments"
          id="cc-page-oec-select-departments"
          class="pt-1 mt-3 mb-0"
          label="Select departments:"
        >
          <div>
            <b-form-radio
              v-model="selectDeptsMode"
              name="select-departments-mode"
              value="all"
              @change="resetDepartments"
            >
              All participating departments
            </b-form-radio>
            <b-form-radio
              v-model="selectDeptsMode"
              name="select-departments-mode"
              value="individual"
              @change="resetDepartments"
            >
              Individual departments
            </b-form-radio>
            <b-alert
              v-if="selectDeptsMode === 'all'"
              class="alert-box m-2 mt-3 overflow-auto"
              show
              variant="info"
            >
              <ul id="cc-page-oec-departments-participating" class="cc-text-small participating-list">
                <li v-for="d in departmentsParticipating" :key="d.code">{{ d.name }}</li>
              </ul>
            </b-alert>
            <b-form-select
              v-if="selectDeptsMode === 'individual'"
              id="cc-page-oec-department-multiselect"
              v-model="departmentCodes"
              class="mt-3"
              :options="departments"
              multiple
              :select-size="15"
              text-field="name"
              value-field="code"
            >
            </b-form-select>
          </div>
        </b-form-group>
        <div v-if="taskName" class="p-3">
          <span id="oec-task-description" class="cc-text-small text-secondary" v-html="$_.get(this.getTaskObject(taskName), 'htmlDescription')"></span>
        </div>
        <div class="p-2">
          <b-button
            id="oec-run-task-button"
            :disabled="!taskName || !term || (taskRequiresDepartments && (selectDeptsMode !== 'all') && !departmentCodes.length)"
            size="sm"
            variant="primary"
            @click="run"
          >
            Run task
          </b-button>
        </div>
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
  components: {RunTask},
  mixins: [Context],
  data: () => ({
    currentTerm: null,
    departmentCodes: [],
    departments: undefined,
    departmentsParticipating: [],
    isTaskRunning: false,
    selectDeptsMode: null,
    taskName: null,
    tasks: undefined,
    term: undefined,
    terms: undefined
  }),
  computed: {
    runTaskDepartmentCodes() {
      return this.selectDeptsMode === 'all' ? 'all_participating' : this.departmentCodes
    },
    taskRequiresDepartments() {
      return ['SisImportTask', 'CreateConfirmationSheetsTask', 'ReportDiffTask', 'MergeConfirmationSheetsTask'].includes(this.taskName)
    }
  },
  created() {
    getTasks().then(data => {
      this.departments = data.oecDepartments
      this.term = this.currentTerm = data.currentTerm
      this.terms = data.oecTerms
      this.tasks = data.oecTasks
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
    resetDepartments() {
      this.departmentCodes = []    
    },
    resetModelObjects() {
      this.departmentCodes = []    
      this.selectDeptsMode = null
    },
    run() {
      this.isTaskRunning = true
    },
    taskRunDone() {
      this.departmentCodes = []    
      this.isTaskRunning = false
      this.selectDeptsMode = null
      this.taskName = null
      this.term = this.currentTerm
    }
  }
}
</script>

<style scoped>
li {
  list-style-type: none;
}
.alert-box {
  height: 300px;
}
</style>
