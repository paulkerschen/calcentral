<template>
  <div>
    <div class="d-flex">
      <div>
        <h3>{{ $_.capitalize(listType) }} Users</h3>
      </div>
      <div>
        (<b-button
          :id="`clear-${listType}-users`"
          class="p-0"
          variant="link"
          @click="clearUsers"
        >
          clear all
        </b-button>)
      </div>
    </div>
    <div>
      <b-table :fields="['UID', 'SID', 'name']" :items="users" small>
        <template v-slot:cell(uid)="data">
          {{ data.item.ldapUid }}
        </template>
        <template v-slot:cell(sid)="data">
          {{ data.item.studentId }}
        </template>
        <template v-slot:cell(name)="data">
          {{ data.item.firstName }} {{ data.item.lastName }}
        </template>
      </b-table>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ActAsSaved',
  props: {
    clearUsers: {
      required: true,
      type: Function
    },
    listType: {
      required: true,
      type: String
    },
    users: {
      required: true,
      type: Array
    }
  }
}
</script>
