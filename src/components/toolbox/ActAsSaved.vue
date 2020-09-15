<template>
  <div>
    <div class="align-items-start d-flex">
      <div class="pr-2 pt-2">
        <h3>{{ $_.capitalize(listType) }} Users</h3>
      </div>
      <div class="pb-2">
        (<b-button
          :id="`clear-${listType}-users`"
          class="pl-0 pr-0"
          variant="link"
          @click="clearUsers"
        >
          clear all
        </b-button>)
      </div>
    </div>
    <div>
      <b-table
        :fields="fields"
        :items="users"
        small
        sort-icon-left
      >
        <template v-slot:cell(uid)="data">
          {{ data.item.ldapUid }}
        </template>
        <template v-slot:cell(sid)="data">
          {{ data.item.studentId }}
        </template>
        <template v-slot:cell(name)="data">
          {{ data.item.firstName }} {{ data.item.lastName }}
        </template>
        <template v-slot:cell(delete)="data">
          <b-button
            :id="`delete-${listType}-user-${data.item.ldapUid}`"
            :aria-label="`Remove user ${data.item.ldapUid} from list of ${listType} users`"
            class="p-0"
            size="sm"
            variant="link"
            @click="deleteRow(data.item.ldapUid)"
          >
            <fa icon="trash-alt" />
          </b-button>
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
    deleteUser: {
      default: undefined,
      required: false,
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
  },
  computed: {
    fields() {
      return [
        {
          key: 'UID',
          sortable: this.users.length > 2
        },
        {
          key: 'SID',
          sortable: this.users.length > 2
        },
        {
          key: 'name',
          sortable: this.users.length > 2
        }
      ]
    }
  },
  created() {
    if (this.deleteUser) {
      this.fields.push({
        class: 'center',
        key: 'delete',
        label: '',
        sortable: false
      })
    }
  },
  methods: {
    deleteRow(uid) {
      this.deleteUser(uid)
    }
  }
}
</script>

<style scoped>
h3 {
  font-size: 1rem;
}
</style>
