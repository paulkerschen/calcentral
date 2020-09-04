<template>
  <b-container>
    <b-row>
      <b-col>
        <ToolboxHeader />
      </b-col>
    </b-row>
    <b-row>
      <b-col>My Toolbox</b-col>
    </b-row>
    <b-row>
      <b-col>1 of 3</b-col>
      <b-col>2 of 3</b-col>
      <b-col>
        <ApiTest />
      </b-col>
    </b-row>
  </b-container>
</template>

<script>
import ApiTest from '@/components/toolbox/ApiTest'
import ToolboxHeader from '@/components/toolbox/ToolboxHeader'

export default {
  name: 'Toolbox',
  components: {ApiTest, ToolboxHeader}
}
</script>
