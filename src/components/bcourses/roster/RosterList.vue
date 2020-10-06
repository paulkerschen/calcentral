<template>
  <div>
    <b-table
      :fields="[
        {
          key: 'student_id',
          label: 'SID',
          sortable: true
        },
        {
          key: 'last_name',
          label: 'Name',
          sortable: true
        },
        {
          key: 'email',
          sortable: true
        },
        {
          key: 'sections',
          sortable: false
        }
      ]"
      hover
      :items="students"
      :sort-by.sync="sortBy"
      striped
    >
      <template #cell(last_name)="data">
        {{ data.item.last_name }}, {{ data.item.first_name }}
      </template>
      <template #cell(sections)="data">
        <div v-for="section in data.item.sections" :key="section.ccn">
          {{ section.name }} ({{ section.ccn }})
        </div>
      </template>
    </b-table>
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Util from '@/mixins/Utils'

export default {
  name: 'RosterList',
  mixins: [Context, Util],
  props: {
    courseId: {
      required: true,
      type: Number
    },
    students: {
      required: true,
      type: Array
    }
  },
  data: () => ({
    context: 'canvas',
    sortBy: undefined
  }),
  watch: {
    sortBy(value) {
      this.alertScreenReader(`Sorted by ${value}`)
    }
  }
}
</script>
