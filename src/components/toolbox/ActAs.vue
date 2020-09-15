<template>
  <div>
    <div>
      <h2>View As</h2>
    </div>
    <div>
      <div>UID/SIS</div>
      <div>
        <b-form-input
          id="basic-auth-uid"
          v-model="userId"
          placeholder="UID"
          size="sm"
          required
        ></b-form-input>
      </div>
      <div>
        <b-button variant="primary" :disabled="!userId" @click="submit">Submit</b-button>
      </div>
    </div>
    <div v-if="$_.size(savedUsers)">
      <ActAsSaved :clear-users="clearSavedUsers" list-type="saved" :users="savedUsers" />
    </div>
    <div v-if="$_.size(recentUsers)">
      <ActAsSaved :clear-users="clearRecentUsers" list-type="recent" :users="recentUsers" />
    </div>
  </div>
</template>

<script>
import ActAsSaved from '@/components/toolbox/ActAsSaved'
import {getMyStoredUsers} from '@/api/act'

export default {
  name: 'ActAs',
  components: {ActAsSaved},
  data: () => ({
    recentUsers: undefined,
    savedUsers: undefined,
    userId: undefined
  }),
  created() {
    getMyStoredUsers().then(data => {
      this.recentUsers = data.users.recent
      this.savedUsers = data.users.saved
    })
  },
  methods: {
    clearRecentUsers() {
      console.log('clearRecentUsers')
    },
    clearSavedUsers() {
      console.log('clearSavedUsers')
    },
    submit() {
      console.log('foo')
    }
  }
}
</script>
