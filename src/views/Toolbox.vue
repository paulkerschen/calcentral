<template>
  <div>
    <div>
      <ToolboxHeader />
    </div>
    <div>
      My Toolbox
    </div>
    <div class="d-flex">
      <div>A</div>
      <div>B</div>
      <div><ApiTest /></div>
    </div>
  </div>
</template>

<script>
import ApiTest from '@/components/toolbox/ApiTest'
import ToolboxHeader from '@/components/toolbox/ToolboxHeader'

export default {
  name: 'Toolbox',
  components: {ApiTest, ToolboxHeader}
}
</script>
