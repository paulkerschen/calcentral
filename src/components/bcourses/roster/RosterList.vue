<template>
  <div class="cc-academics-class-enrollment-table">
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
        <span :id="`student-name-${data.item.student_id}`">
          {{ data.item.last_name }}, {{ data.item.first_name }}
        </span>
      </template>
      <template #cell(sections)="data">
        <div
          v-for="section in data.item.sections"
          :id="`student-${data.item.student_id}-section-${section.ccn}`"
          :key="section.ccn"
        >
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

<style scoped>
@media print {
  .cc-academics-class-enrollment-table {
    table tr th {
      padding: 2px;
      vertical-align: top;
    }
    table tr td {
      font-size: 10px;
      line-height: normal;
      padding: 2px;
    }
  }
}
</style>