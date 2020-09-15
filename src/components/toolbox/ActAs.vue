<template>
  <div>
    <div>
      <h2>View As</h2>
    </div>
    <div>
      <div>
        <b-form-input
          id="basic-auth-uid"
          v-model="userId"
          placeholder="Enter UID or SID"
          size="sm"
          required
        ></b-form-input>
      </div>
      <div class="d-flex justify-content-between pl-2 pt-2">
        <div>
          <b-button
            id="view-as-submit"
            :disabled="!userId"
            size="sm"
            variant="primary"
            @click="submit"
          >
            Submit
          </b-button>
        </div>
        <div class="pt-1">
          <a href="https://www.berkeley.edu/directory" target="_blank">Campus Directory<span class="sr-only"> will open in a new tab</span></a>
        </div>
      </div>
    </div>
    <div v-if="$_.size(savedUsers)" class="pl-1 pt-3">
      <ActAsSaved
        :clear-users="clearSavedUsers"
        :delete-user="deleteSavedUser"
        list-type="saved"
        :users="savedUsers"
      />
    </div>
    <div v-if="$_.size(recentUsers)" class="pl-1 pt-3">
      <ActAsSaved :clear-users="clearRecentUsers" list-type="recent" :users="recentUsers" />
    </div>
  </div>
</template>

<script>
import ActAsSaved from '@/components/toolbox/ActAsSaved'
import Context from '@/mixins/Context'
import {getMyStoredUsers, removeAllRecentUsers, removeAllSavedUsers, removeSavedUser} from '@/api/act'

export default {
  name: 'ActAs',
  components: {ActAsSaved},
  mixins: [Context],
  data: () => ({
    recentUsers: undefined,
    savedUsers: undefined,
    userId: undefined
  }),
  created() {
    this.refresh().then(() => {
      this.$ready('Act As')
    })
  },
  methods: {
    clearRecentUsers() {
      removeAllRecentUsers().then(() => {
        this.refresh()
        this.alertScreenReader('Recent users cleared.')
      })
    },
    clearSavedUsers() {
      removeAllSavedUsers().then(() => {
        this.refresh()
        this.alertScreenReader('Saved users cleared.')
      })
    },
    deleteSavedUser(uid) {
      removeSavedUser(uid).then(() => {
        this.refresh()
        this.alertScreenReader(`User ${uid} removed.`)
      })
    },
    refresh() {
      return getMyStoredUsers().then(data => {
        this.recentUsers = data.users.recent
        this.savedUsers = data.users.saved
      })
    },
    submit() {
      console.log('foo')
    }
  }
}
</script>

<style scoped>
h2 {
  font-size: 18px;
}
</style>
