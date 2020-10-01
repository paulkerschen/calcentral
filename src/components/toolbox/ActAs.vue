<template>
  <div>
    <div>
      <h2 class="cc-text-big">View As</h2>
    </div>
    <div>
      <b-form @submit="actAsUser(uidInput)">
        <div>
          <b-form-input
            id="basic-auth-uid"
            v-model="uidInput"
            placeholder="Enter UID or SID"
            size="sm"
            required
          ></b-form-input>
        </div>
        <div class="d-flex justify-content-between pl-2 pt-2">
          <div>
            <b-button
              id="view-as-submit"
              :disabled="!uidInput || uidInput === $currentUser.uid"
              size="sm"
              variant="primary"
              @click="actAsUser"
            >
              Submit
            </b-button>
          </div>
          <div class="pt-1">
            <OutboundLink href="https://www.berkeley.edu/directory">Campus Directory</OutboundLink>
          </div>
        </div>
      </b-form>
    </div>
    <div v-if="$_.size(savedUsers)" class="pl-1 pt-3">
      <ActAsSaved
        :act-as="actAsUser"
        :action="deleteSavedUser"
        action-icon="trash-alt"
        action-verb="remove"
        :clear-users="clearSavedUsers"
        list-type="saved"
        :users="savedUsers"
      />
    </div>
    <div v-if="$_.size(recentUsers)" class="pl-1 pt-3">
      <ActAsSaved
        :act-as="actAsUser"
        :action="saveUser"
        action-icon="plus"
        action-verb="save"
        :clear-users="clearRecentUsers"
        list-type="recent"
        :users="recentUsers"
      />
    </div>
  </div>
</template>

<script>
import ActAsSaved from '@/components/toolbox/ActAsSaved'
import Context from '@/mixins/Context'
import OutboundLink from '@/components/util/OutboundLink'
import {
  actAs,
  getMyStoredUsers,
  removeAllRecentUsers,
  removeAllSavedUsers,
  removeSavedUser, storeUserAsRecent,
  storeUserAsSaved
} from '@/api/act'

export default {
  name: 'ActAs',
  components: {ActAsSaved, OutboundLink},
  mixins: [Context],
  data: () => ({
    recentUsers: undefined,
    savedUsers: undefined,
    uidInput: undefined
  }),
  created() {
    this.refresh()
  },
  methods: {
    clearRecentUsers() {
      removeAllRecentUsers().then(() => {
        this.refresh().then(() => {
          this.alertScreenReader('Recent users cleared.')
        })
      })
    },
    clearSavedUsers() {
      removeAllSavedUsers().then(() => {
        this.refresh().then(() => {
          this.alertScreenReader('Saved users cleared.')
        })
      })
    },
    deleteSavedUser(uid) {
      removeSavedUser(uid).then(() => {
        this.refresh().then(() => {
          this.alertScreenReader(`User ${uid} removed.`)
        })
      })
    },
    refresh() {
      return getMyStoredUsers().then(data => {
        this.recentUsers = data.users.recent
        this.savedUsers = data.users.saved
      })
    },
    saveUser(uid) {
      storeUserAsSaved(uid).then(() => {
        this.refresh().then(() => {
          this.alertScreenReader(`User ${uid} saved.`)
        })
      })
    },
    actAsUser(uid) {
      actAs(uid).then(() => {
        this.alertScreenReader(`Prepare to act as user ${uid}.`)
        storeUserAsRecent(uid).then(() => window.location.href = '/')
      })
    }
  }
}
</script>
