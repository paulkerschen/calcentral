import utils from '@/api/api-utils'

export function getDeptsReadyToPublish(termCode: string) {
  return utils.get(`/api/oec/depts_ready_to_publish/${termCode}`)
}

export function getTasks() {
  return utils.get('/api/oec/tasks')
}

export function getStatus(taskId) {
  return utils.get(`/api/oec/tasks/status/${taskId}`)
}

export function runTask(taskName: string, termName: string, departmentCode) {
  return utils.post(`/api/oec/tasks/${taskName}`, {
    departmentCode,
    term: termName
  })
}
