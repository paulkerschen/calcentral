module.exports = {
  publicPath: process.env.NODE_ENV === 'production' ? '/static' : '/',
  lintOnSave: process.env.NODE_ENV !== 'production',
  css: {
  	loaderOptions: {
  	  scss: {
  	  	// Make global SCSS variables available to scoped styles in individual components.
  	  	additionalData: `@import "~@/assets/styles/colors.scss"; @import "~@/assets/styles/_canvas_colors.scss"; @import "~@/assets/styles/_canvas_base.scss"; @import "~@/assets/styles/_bootstrap_variables.scss";`
  	  }
  	}
  }
}
