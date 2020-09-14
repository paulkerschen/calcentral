<template>
  <ul>
    <li v-for="(value, key) in summary" :key="key">
      <ul v-if="value instanceof Object">
        <li v-for="(innerValue, innerKey) in value" :key="innerKey">
          <span class="font-weight-bolder">{{ decamelize(innerKey) }}:</span> {{ innerValue }}
        </li>
      </ul>
      <span v-if="!(value instanceof Object)">
        <span class="font-weight-bolder">{{ decamelize(key) }}: </span>
        <span v-if="key === 'gitCommit'">
          <a :href="`https://github.com/ets-berkeley-edu/calcentral/commit/${value}`" target="_blank">{{ value.substring(0, 7) }}<span class="sr-only"> (will open new browser tab)</span></a>
        </span>
        <span v-if="key !== 'gitCommit'">{{ value }}</span>
      </span>
    </li>
  </ul>
</template>

<script>
import Utils from '@/mixins/Utils'
import {serverInfo} from '@/api/config'

export default {
  name: 'BuildSummary',
  mixins: [Utils],
  data: () => ({
    summary: undefined
  }),
  created() {
    serverInfo().then(data => {
      this.summary = data
    })
  }
}
</script>
