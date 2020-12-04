<template>
  <div>
    <div id="oec-task-started-notice" class="cc-oec-text">
      Your <span class="font-weight-bolder">{{ task.friendlyName }}</span> task has started.
      Results will appear in
      <a
        id="oec-google-drive-href"
        :href="googleDriveUrl"
        target="_blank"
      >your Google Drive account<span class="sr-only"> (link will open a new browser tab)</span></a>.
    </div>
    <b-alert
      id="log-output"
      class="alert-box m-2 overflow-auto"
      show
      :variant="(!status || status === 'In progress') ? 'info' : status === 'Error' ? 'danger' : 'success'"
    >
      <div v-if="$_.size(output)">
        <div v-for="(row, index) in output" :key="index" class="oec-log">
          <span v-if="index < output.length - 1">{{ row }}</span>
          <span v-if="index === output.length - 1" aria-live="polite" role="alert">{{ row }}</span>
        </div>
        <div
          v-if="status !== 'In progress'"
          class="font-weight-bolder py-2 task-status"
        >
          {{ status }}
        </div>
      </div>
      <div v-if="!$_.size(output)">
        Loading...
      </div>
    </b-alert>
    <div v-if="this.status !== 'In progress'" class="pt-2">
      <b-button
        id="oec-task-complete-back-button"
        size="sm"
        variant="primary"
        @click="onFinish"
      >
        Back
      </b-button>
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
      type: [Array, String]
    },
    onFinish: {
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
    isDone: false,
    output: undefined,
    pollingErrorCount: 0,
    status: undefined,
    taskId: undefined,
    taskMonitor: undefined
  }),
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
        clearTimeout(this.taskMonitor)
        this.output = data.oecTaskStatus.log
        this.status = ['Error', 'In progress', 'Success'].includes(data.oecTaskStatus.status) ? data.oecTaskStatus.status : 'Error'

        if (this.status === 'In progress') {
          this.pollingErrorCount = 0
          this.taskMonitor = setTimeout(this.getTaskStatus, 1500)
        } else if (this.status === 'Error') {
          this.pollingErrorCount++
          if (this.pollingErrorCount === 3) {
            this.isDone = true
          } else {
            this.taskMonitor = setTimeout(this.getTaskStatus, 1500)
          }
        } else {
          // Success!
          this.isDone = true
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
.oec-log {
  white-space: pre;
}
.task-status {
  font-size: 14px;
}
</style>
