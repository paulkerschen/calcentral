<template>
  <b-container fluid>
    <b-row>
      <b-col>
        <ToolboxHeader />
      </b-col>
    </b-row>
    <b-row>
      <b-col sm="9">
        {{ $currentUser.firstName }}'s Toolbox
        <b-row>
          <b-col cols="8" sm="6">Level 2: cols="8" sm="6"</b-col>
          <b-col cols="4" sm="6"><ApiTest /></b-col>
        </b-row>
      </b-col>
    </b-row>
    <b-row>
      <b-col>
        <Footer />
      </b-col>
    </b-row>
  </b-container>
</template>

<script>
import ApiTest from '@/components/toolbox/ApiTest'
import Footer from '@/components/Footer'
import ToolboxHeader from '@/components/toolbox/ToolboxHeader'

export default {
  name: 'Toolbox',
  components: {ApiTest, Footer, ToolboxHeader}
}
</script>
