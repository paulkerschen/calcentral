<template>
  <div>
    <div class="cc-oec-text">
      Your <span class="font-weight-bolder">{{ task.friendlyName }}</span> task has started.
      Results will appear in
      <a
        id="google-drive=href"
        :href="googleDriveUrl"
        target="_blank"
      >your Google Drive account<span class="sr-only"> (link will open a new browser tab)</span></a>.
    </div>
    <b-alert
      id="log-output"
      class="alert-box m-2 overflow-auto"
      show
      :variant="(!status || isInProgress) ? 'info' : isError ? 'danger' : 'success'"
    >
      <div v-if="$_.size(output)">
        <div v-for="(row, index) in output" :key="index">
          <span v-if="index < output.length - 1">{{ row }}</span>
          <span v-if="index === output.length - 1" aria-live="polite" role="alert">{{ row }}</span>
        </div>
      </div>
      <div v-if="!$_.size(output)">
        Loading...
      </div>
    </b-alert>
    <div v-if="!isInProgress" class="pt-2">
      <b-button size="sm" variant="primary" @click="done">Back</b-button>
    </div>
  </div>
</template>

<script>
import {getStatus, runTask} from '@/api/oec'

export default {
  name: 'RunTask',
  props: {
    departmentCode: {
      default: undefined,
      required: false,
      type: Object
    },
    done: {
      required: true,
      type: Function
    },
    task: {
      required: true,
      type: Object
    },
    term: {
      required: true,
      type: String
    }
  },
  data: () => ({
    googleDriveUrl: undefined,
    pollingErrorCount: 0,
    output: undefined,
    status: undefined,
    taskId: undefined,
    taskMonitor: undefined
  }),
  computed: {
    isError() {
      return this.status === 'Error'
    },
    isInProgress() {
      return this.status === 'In progress'
    }
  },
  created() {
    runTask(this.task.name, this.term, this.departmentCode).then(data => {
      this.googleDriveUrl = data.oecDriveUrl
      this.status = data.oecTaskStatus.status
      this.taskId = data.oecTaskStatus.id
      this.getTaskStatus()
    })
  },
  methods: {
    getTaskStatus() {
      getStatus(this.taskId).then(data => {
        this.output = data.oecTaskStatus.log
        this.status = data.oecTaskStatus.status
        if (this.isInProgress) {
          this.pollingErrorCount = 0
          this.taskMonitor = setTimeout(this.getTaskStatus, 1500)
        } else if (this.status === 'Error') {
          this.pollingErrorCount++
          if (this.pollingErrorCount === 3) {
            // this.done()
          } else {
            this.taskMonitor = setTimeout(this.getTaskStatus, 1500)
          }
        }
        setTimeout(() => {
          let element = document.getElementById('log-output')
          if (element) {
            element.scrollTop = element.scrollHeight
          }
        }, 100)
      })
    }
  }
}
</script>

<style scoped>
.alert-box {
  height: 300px;
}
</style>
