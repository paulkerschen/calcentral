import utils from '@/api/api-utils'

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
