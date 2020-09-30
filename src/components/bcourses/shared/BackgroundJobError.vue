<template>
  <div class="bc-template-background-job-error">
    <p class="bc-template-background-job-error-paragraph">
      <i class="cc-left fa fa-exclamation-circle cc-icon-red bc-template-background-job-error-icon"></i>
      <span class="bc-template-background-job-error-header">{{ errorConfig.header }}</span>
    </p>
    <p class="bc-template-background-job-error-paragraph">
      Due to technical issues encountered, our support team must {{ errorConfig.supportAction }}.
    </p>
    <p class="bc-template-background-job-error-paragraph">
      Please email us at
      <a
        :href="`bcourseshelp@berkeley.edu?subject=bCourses+Course+Site+Creation+Failure`"
        target="_blank"
        aria-label="Send email to the bCourses support team"
      >
        bcourseshelp@berkeley.edu<span class="sr-only"> (new browser tab will open)</span>
      </a> with:
    </p>
    <ul>
      <li v-for="(info, index) in errorConfig.supportInfo" :key="index">
        {{ info }}
      </li>
      <li v-if="errors">The following error messages:</li>
      <ul>
        <li v-for="(error, index) in errors" :key="index">
          {{ error }}
        </li>
      </ul>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'BackgroundJobError',
  props: {
    errorConfig: {
      required: true,
      type: Object
    },
    errors: {
      required: true,
      type: Array
    }
  },
  methods: {
    errorEmail() {
      window.top.location = 'mailto:bcourseshelp@berkeley.edu?subject=bCourses+Course+Site+Creation+Failure'
    }
  }
}
</script>
