<script>
  export default {
    name: 'CanvasUtils',
    methods: {
      getCanvasCourseId() {
        const idParam = this.$_.get(this.$route, 'params.id')
        if (idParam) {
          this.canvasCourseId = this.toInt(idParam)
        } else {
          this.canvasCourseId = 'embedded'
        }
      }
    }
  }
</script>
