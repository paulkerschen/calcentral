<template>
  <b-container>
    <b-row>
      <b-col sm="6">
        <div class="d-flex flex-wrap">
          <div>
            <b-input placeholder="Search People"></b-input>
          </div>
          <div>
            <b-dropdown size="lg" text="Large" class="m-2">
              <b-dropdown-item-button>1</b-dropdown-item-button>
              <b-dropdown-item-button>2</b-dropdown-item-button>
              <b-dropdown-item-button>3</b-dropdown-item-button>
            </b-dropdown>
          </div>
        </div>
      </b-col>
      <b-col sm="6">
        <div class="float-right">
          <div class="d-flex flex-wrap">
            <div>
              <b-button class="cc-text-light" size="lg" variant="cc-light"><fa class="text-dark" icon="file-download" /> Export</b-button>
            </div>
            <div>
              <b-button class="cc-button-blue" size="lg" variant="cc-blue"><fa icon="print" variant="primary" /> Print</b-button>
            </div>
          </div>
        </div>
      </b-col>
    </b-row>
  </b-container>
</template>

<script>
export default {
  name: 'RosterHeader'
}
</script>
