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
        <template #cell(ldapUid)="data">
          <b-button
            id="act-as-by-uid"
            class="p-0"
            variant="link"
            @click="actAs(data.item.ldapUid)"
          >
            {{ data.item.ldapUid }}
          </b-button>
        </template>
        <template #cell(studentId)="data">
          {{ data.item.studentId || '&mdash;' }}
        </template>
        <template #cell(firstName)="data">
          {{ data.item.firstName }} {{ data.item.lastName }}
        </template>
        <template #cell(action)="data">
          <b-button
            :id="`${actionVerb}-user-${data.item.ldapUid}`"
            :aria-label="`${actionVerb} user ${data.item.ldapUid}`"
            class="p-0"
            size="sm"
            variant="link"
            @click="performAction(data.item.ldapUid)"
          >
            <fa :icon="actionIcon" />
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
    actAs: {
      required: true,
      type: Function
    },
    action: {
      required: true,
      type: Function
    },
    actionIcon: {
      required: true,
      type: String
    },
    actionVerb: {
      required: true,
      type: String
    },
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
  },
  computed: {
    fields() {
      return [
        {
          key: 'ldapUid',
          sortable: this.users.length > 2
        },
        {
          key: 'studentId',
          sortable: this.users.length > 2
        },
        {
          key: 'firstName',
          sortable: this.users.length > 2
        },
        {
          class: 'text-center',
          key: 'action',
          label: this.$_.capitalize(this.actionVerb) + '?',
          sortable: false
        }
      ]
    }
  },
  methods: {
    performAction(uid) {
      this.action(uid)
    }
  }
}
</script>

<style scoped>
h3 {
  font-size: 1rem;
}
</style>
