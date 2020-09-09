<template>
  <div v-if="!loading">
    <h2>OEC Control Panel</h2>
    <b-container>
      <b-row>
        <b-col class="text-right">
          Task to run:
        </b-col>
        <b-col cols="8">
          <b-form-select
            v-model="selectedTask"
            :options="tasks"
            value-field="name"
            text-field="friendlyName"
            placeholder="Choose a task"
          >
            <b-form-select-option :value="null">Choose a task</b-form-select-option>
          </b-form-select>
        </b-col>
      </b-row>
      <b-row>
        <b-col class="text-right">
          Term:
        </b-col>
        <b-col cols="8">
          <b-form-select
            v-model="selectedTerm"
            :options="terms"
            option-label="friendlyName"
          ></b-form-select>
        </b-col>
      </b-row>
      <b-row>
        <b-col></b-col>
        <b-col cols="8">
          <b-button :disabled="!selectedTask || !selectedTerm" @click="run">Run task</b-button>
        </b-col>
      </b-row>
      <b-row v-if="taskDescription">
        <b-col></b-col>
        <b-col>
          <span v-html="taskDescription"></span>
        </b-col>
      </b-row>
    </b-container>
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import {getTasks, runTask} from '@/api/oec'

export default {
  name: 'Oec',
  data: () => ({
    selectedTask: null,
    selectedTerm: null,
    tasks: undefined,
    terms: undefined
  }),
  mixins: [Context],
  computed: {
    taskDescription() {
      return this.selectedTask ? this.$_.get(this.$_.find(this.tasks, ['name', this.selectedTask]), 'htmlDescription') : null
    }
  },
  created() {
    this.$loading()
    getTasks().then(data => {
      this.selectedTerm = data.currentTerm
      this.tasks = data.oecTasks
      this.terms = data.oecTerms
      this.$ready('OEC Tasks')
    })
  },
  methods: {
    run() {
      runTask(this.selectedTask, this.selectedTerm, null).then(status => {
        console.log(status)
      })
    }
  }
}
</script>
