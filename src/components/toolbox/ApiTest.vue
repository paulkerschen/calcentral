<template>
  <b-card
    header="API Test"
    header-tag="header"
    title="Title"
  >
    <b-card-text>
      <div v-if="results">
        <ul>
          <li v-for="row in results" :key="row.api">
            <span v-if="$_.isNil(row.status)">
              <b-icon icon="arrow-clockwise" animation="spin" variant="warning"></b-icon> {{ row.api }}
            </span>
            <span v-if="!$_.isNil(row.status)">
              <span v-if="!row.success"><b-icon icon="x" variant="danger"></b-icon> {{ row.api }}</span>
              <span v-if="row.success"><b-icon icon="success"></b-icon> {{ row.api }}</span>
            </span>
          </li>
        </ul>
      </div>
    </b-card-text>
    <b-button id="run-api-test" variant="primary" @click="apiTest">Run</b-button>
  </b-card>
</template>

<script>
import {ping, serverInfo} from '@/api/config'
import {isUserLoggedIn, myStatus} from '@/api/user'
import {canUserCreateSite, externalTools} from '@/api/canvas'

export default {
  name: 'ApiTest',
  data: () => ({
    results: undefined
  }),
  methods: {
    apiTest() {
      this.results = []
      const apis = [
        canUserCreateSite,
        externalTools,
        isUserLoggedIn,
        myStatus,
        ping,
        serverInfo
      ]
      this.$_.each(apis, api => {
        console.log(api)
        api.call().then(data => {
          this.results.push({
            api,
            success: data !== null
          })
        })
      })
    }
  }
}
</script>

<style scoped>
.cc-toolbox-apitest-pending {
  color: $cc-color-night-rider;
}
.cc-toolbox-apitest-failed {
  color: $cc-color-harley-davidson-orange;
}
.cc-toolbox-apitest-success {
  color: $cc-color-salem;
}
</style>
