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
    <div v-if="log">
      {{ log }}
    </div>
    <div>
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
      required: true,
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
    log: undefined,
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
        this.log = data.oecTaskStatus.log
        if (data.oecTaskStatus.status === 'In Progress') {
          this.taskMonitor = setTimeout(this.getTaskStatus, 2000)
        } else {
          this.done()
        }
      })
    }
  }
}
</script>
